// External.c - implements external C function calling pascal.

#include "MainExports.h"

SInt32 CFunction(void)
{
	Str255 msg;
	
	// use GetIndString just to use data fork resources
	GetIndString(msg, 128, 1);
	
	// call back to pascal main:
	Message(msg);

	return 123;
}
