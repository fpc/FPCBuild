#!/bin/sh

# Default read-only HTTP URL used for externals
SVNHTTPURL=http://svn.freepascal.org/svn

if [ $# -lt 1 ]; then
  echo "Usage: $0 <branch/tag name>"
  echo
  echo "Example: $0 branches/fixes_2_1"
  echo "         $0 tags/release_2_0_4"
  echo
  exit 1
fi
NEWSVNTAG=$1

# For testing output the svn commands
if [ ."$2" = ."test" ]; then
  SVN="echo svn"
else
  SVN=svn
fi

# Decode SVN URL from current fpcbuild URL
FPCBUILDURL=`svn info . | grep URL | grep fpcbuild`
if [ $? -ne 0 ]; then
  echo "This is not an fpcbuild checkout"
fi
SVNURL=`echo $FPCBUILDURL | sed -e 's+URL: ++' -e 's+/fpcbuild/.*$++'`
OLDSVNTAG=`echo $FPCBUILDURL | sed -e 's+URL:.*fpcbuild/++'`
COMMITMSG="Creating branch $NEWSVNTAG"

echo "SVN URL: $SVNURL"
echo "Old SVN (branch) dir: $OLDSVNTAG"
echo "New SVN (branch) dir: $NEWSVNTAG"

$SVN copy $SVNURL/fpc/$OLDSVNTAG $SVNURL/fpc/$NEWSVNTAG -m "$COMMITMSG"
$SVN copy $SVNURL/fpcbuild/$OLDSVNTAG $SVNURL/fpcbuild/$NEWSVNTAG -m "$COMMITMSG"

# Generate svn:externals property
cat << EXTERNALEOF > external.lst
fpcsrc $SVNHTTPURL/fpc/$NEWSVNTAG
fpcdocs $SVNHTTPURL/fpcdocs/trunk
logs $SVNHTTPURL/logs
EXTERNALEOF
echo
echo "External list:"
echo "===="
cat external.lst
echo "===="
echo

# Setting properties on a remote URL is not supported.
# To workaround we need to do a (non-recursive) checkout of the
# just created fpcbuild branch
$SVN co -N $SVNURL/fpcbuild/$NEWSVNTAG branchtmp
$SVN ps -F external.lst svn:externals branchtmp

# Commit and cleanup
$SVN ci branchtmp -m "$COMMITMSG" && rm -rf branchtmp && rm -f external.lst
