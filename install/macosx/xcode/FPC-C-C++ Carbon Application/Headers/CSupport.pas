unit CSupport; { pascal interface for external C functions }

interface

uses
	MacTypes;
	
function CFunction: SInt32; C;
function CPlusFunction: SInt32; C;
	
end.
