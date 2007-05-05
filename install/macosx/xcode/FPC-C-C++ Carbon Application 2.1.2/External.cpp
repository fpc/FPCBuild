// External.cpp - useless C++ code calling pascal main.

#include <limits>

#include "MainExports.h"

template <typename T>
struct Horror
{
	void Message() { Message(Selector<IsInteger<T>::yes>()); }
	
private:

	template <bool> struct Selector {};

	void Message(Selector<true>) {
		::Message("\pCalling pascal from template Horror<T> [T=int]");
	}
	void Message(Selector<false>) { throw 1; }
	
    template <typename I> struct IsInteger
    {
        enum { yes = std::numeric_limits<I>::is_integer };
    };
};

extern "C" {

SInt32 CPlusFunction()
{
	try // call pascal from C++ template instances
	{
		Horror<short>().Message();
		Horror<float>().Message();
	}
	catch (...)
	{
		Message("\pCalling pascal from a C++ catch");
	}
	
	// C++ fun is over, go home to mother pascal :)
	return 456;
}

} // extern "C"
