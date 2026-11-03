#include "../../../runtime/src/allocator/Heap.hpp"
extern "C" {
void Eco_Kernel_File_read(int x) { Elm::allocate(x); }
}
