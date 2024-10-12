
#pragma once

//#ifdef __cplusplus
//extern "C"
//{
//#endif

#include <utility>
#include <opencv2/opencv.hpp>
#include "ncnn/ncnn/net.h"
const char* check_version_ncnn_wrapper();


class GuidedFilter
{
public:
    // Constructor
    GuidedFilter(int r, float eps, float alpha, float beta);
    // Method for guided filtering
    std::pair<cv::Mat, cv::Mat> guidedFilter(const cv::Mat &I, const cv::Mat &p, int height, int width);
private:
    int r;     // Radius
    float eps; // Regularization parameter
    float alpha;
    float beta;
};

class VideoEnhancementPipeline
{
public:
    VideoEnhancementPipeline(ncnn::Net &net);
    
    ~VideoEnhancementPipeline();
    void enhanceFrameNCNN(cv::Mat frame, cv::Mat& enhanced_frame);
    void enhanceFrameGuidedFilter(cv::Mat frame, cv::Mat &enhanced_frame);
    void enhanceFrame(const cv::Mat &frame, cv::Mat &enhanced_frame);
    void setSkipFrame(int skipframe);
    
private:
    ncnn::Net &net;
    int input_width;
    int input_height;
    int counter;
    int skipframe;
    GuidedFilter* gf;
    cv::Mat matrix_A;
    cv::Mat matrix_B;
    ncnn::Mat in;
    ncnn::Mat out;
};

//
//#ifdef __cplusplus
//}
//#endif

