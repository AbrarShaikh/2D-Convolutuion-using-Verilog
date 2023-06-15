# 2D-Convolutuion-using-Verilog

## Abstract
2-D convolution operation is regarded as the most crucial step in convolutional neural nets. The main reason for that is the whole-time complexity of this algorithm, which determines the amount of time taken by the model to fetch the output depends on this operation. Hence, efficient implementation of convolution operation is required because it is the most computation intensive step in the whole network.

## INTRODUCTION 
2D Convolution is Neighbourhood Processing where operation is performed not only the its current value but based on its neighbour values also depending on size of Kernel or Filter. In the digital domain, convolution is performed by multiplication and accumulation of the instantaneous values of the mutually overlapping weights corresponding to two input signals. The filter size is smaller than the input data and the type of multiplication applied between a sampled input data and the filter is a dot product. 
This kind of operation is widely used in the field of digital image processing wherein the 2D matrix representing the image is being convolved with a 2D kernel. Convolutional layers are the major building blocks used in convolutional neural networks. Technically, the convolution as described in the use of convolutional neural networks is actually a “cross-correlation” [1].

## DESIGN
### Line Buffer
Pure streaming architecture can’t be used for convolution operation since image pixel for processing is not consecutive. The most bottle neck process in convolution is reading image input as image frames and other large data sets are usually stored in off-chip memory because of their large size. cache is has faster access than re-reading the data from external memory, but caching entire image is not feasible. In an FPGA, a cache can be used to buffer accesses to external memory before processing. It can help to smooth the flow of data between off-chip memory and FPGA. One of the common ways to cache the input image is line/row buffering.

![image](https://github.com/AbrarShaikh/2D-Convolutuion-using-Verilog/assets/34272376/e1d5a679-57b3-451a-95b0-73c14686dede)

### MAC opperation
AC stands for multiply accumulate. So, in this particular module corresponding elements of two matrices which are the kernel and input image matrix are multiplied and then added . Hence the kernel is strided onto the whole image matrix and in each stride MAC operation is performed. The kernel which is to be strided depends on the application. Various kernels are available for different applications like image blurring, edge detection etc. Higher order filters tend to extract out more features rather than lower order filters.

![image](https://github.com/AbrarShaikh/2D-Convolutuion-using-Verilog/assets/34272376/b158fc14-9140-4d07-bc99-811fafe4de4f)

### Controller FSM
Three line buffers are placed in parallel to scan input image, so that it can be streamed to perform MAC operation for first iteration. The last buffer is used to next image line for next iteration, which reduces the latency of fetching.
On the other hand, the picture may be partitioned with several filters working concurrently if sufficient resources and memory bandwidth exist. It can be more efficient to simultaneously analyse many neighbouring lines, instead of partitioning the image.
If the scan loop is partially unrolling vertically, pixel reading from k picture rows is required. These pixels, however, are not often saved in memory with an embarrassing pattern of memory access. It is more likely that pixels are packed in memory, such that several horizontals may be read. At the same time, pixels. The horizontal partial unrolling of the scan loop.

![image](https://github.com/AbrarShaikh/2D-Convolutuion-using-Verilog/assets/34272376/4e4d1cbf-b3ce-4dfb-839e-06e35e56d5cd)

## SIMULATION
The top module consists of submodules which are line buffer, MAC and control signal. So, for a particular duration of time we can see that outData signal is 0, this is due to the fact that, the necessary condition for convolution operation to happen there should be enough data in the line buffers. Therefore, after some duration we can see some values in outData as shown in Figure (4), this is because at that point of time line buffers are filled with adequate amount of data for convolution operation to occur.
INTR signal continues to get triggered whenever the IP requires a new row. This will happen till the receivedData signal which is the last signal in waveform window, will be equal to the size of the input image matrix which is 40000 (hex value of 512x512).

![image](https://github.com/AbrarShaikh/2D-Convolutuion-using-Verilog/assets/34272376/db784de2-dcad-45fc-a092-1c63c68d9df8)

## REFERENCES
[1]	Towardsdatascience.com/intuitively-understanding-convolutions-for-deep-learning.
[2]	J Roger Woods, “ FPGA-based Implementation of Signal Processing Systems”, WILEY, ISBN 9781119077954.

