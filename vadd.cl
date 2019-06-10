/**********
Copyright (c) 2017, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/

/*******************************************************************************
Description:
    OpenCL Wide Memory Read/write Example 
    Description: This is vector addition to demonstrate Wide Memory access of 
    128bit Datawidth using uint4 openCL vector datatype.
*******************************************************************************/

#define LOCAL_MEM_SIZE  32
#define VECTOR_SIZE     4 //   using uint4 datatype so vector size is 4

/*
    Vector Addition Kernel Implementation using uint4 datatype 
    Arguments:
        in1   (input)     --> Input Vector1
        in2   (input)     --> Input Vector2
        out   (output)    --> Output Vector
        size  (input)     --> Size of Vector in Integer
   */
kernel __attribute__ ((reqd_work_group_size(1, 1, 1)))
void vadd(
        const __global uint4 *in1, // Read-Only Vector 1
        const __global uint4 *in2, // Read-Only Vector 2
        __global uint4 *out,       // Output Result
        int size                   // Size in integer
        )
{
    local uint4 v1_local[LOCAL_MEM_SIZE];    // Local memory to store vector1
    local uint4 result_local[LOCAL_MEM_SIZE];// Local Memory to store result

    // Input vector size is in integer. It has to be changed into
    // Size of int4. 
    int size_in4 = (size-1) / VECTOR_SIZE + 1; 

    //Per iteration of this loop perform LOCAL_MEM_SIZE vector addition
    for(int i = 0; i < size_in4;  i += LOCAL_MEM_SIZE)
    {
        int chunk_size = LOCAL_MEM_SIZE;

        //boundary checks
        if ((i + LOCAL_MEM_SIZE) > size_in4) 
            chunk_size = size_in4 - i;

        //burst read first vector from global memory to local memory
        v1_rd: __attribute__((xcl_pipeline_loop))
        for (int j = 0 ; j <  chunk_size; j++){
            v1_local[j] = in1 [i + j];
        }

        //burst read second vector and perform vector addition
        v2_rd_add: __attribute__((xcl_pipeline_loop))
        for (int j = 0 ; j < chunk_size; j++){
            uint4 tmpV1     = v1_local[j];
            uint4 tmpV2     = in2[i+j];
            result_local[j] = tmpV1 + tmpV2; // Vector Addition Operation
        }

        //burst write the result
        out_wr:__attribute__((xcl_pipeline_loop))
        for (int j = 0 ; j < chunk_size; j++)
            out[i+j] = result_local[j];
    }
}
