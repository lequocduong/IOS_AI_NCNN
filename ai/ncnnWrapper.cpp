//
//  ncnnWrapper.cpp
//  cpp_inf
//
//  Created by Puwell on 13/9/24.
//

#include <stdio.h>
#include "ncnn/ncnn/net.h"
#include "ncnnWrapper.hpp"
#include <opencv2/opencv.hpp>
#include <chrono>
#include <iostream>
#include <dirent.h>

// class enhancement

VideoEnhancementPipeline::VideoEnhancementPipeline(ncnn::Net &net): net(net)
{
    // Assign the provided net to the class member
    this->input_width = 1920 / 12;
    this->input_height = 1080 / 12;
    int r = 24;
    float eps = 0.00000001f;
    float alpha = 1.5f;
    float beta = 1.2f;
    this->gf = new GuidedFilter(r, eps, alpha, beta);
    this->skipframe = 30;
    this->counter = 0;
}
// Destructor to clean up resources
VideoEnhancementPipeline::~VideoEnhancementPipeline()
{
    delete this->gf;
};
// Method to enhance the frame using the NCNN model
void VideoEnhancementPipeline::enhanceFrameNCNN(cv::Mat frame, cv::Mat &enhanced_frame)
{
    const float scal[] = {0.003915, 0.003915, 0.003915};
    const float scal2[] = {255, 255, 255};
    ncnn::Extractor extractor = this->net.create_extractor();

    cv::cvtColor(frame, frame, cv::COLOR_BGR2RGB);

    // Resize the frame to the desired size
    cv::Mat resized_frame;
    cv::resize(frame, resized_frame, cv::Size(this->input_width, this->input_height));

    // Convert the frame to ncnn Mat format
    in = ncnn::Mat::from_pixels(resized_frame.data, ncnn::Mat::PIXEL_RGB, resized_frame.cols, resized_frame.rows);

    // Normalize the input frame to the range of 0-1
    in.substract_mean_normalize(0, scal); // 0-255  -->  0-1

    // Perform Inference
    extractor.input("in0", in);
    extractor.extract("out0", out);

//    std::cout << "Done Inference" << std::endl;

    // Denormalize the output
    out.substract_mean_normalize(0, scal2);

    // Convert NCNN output back to OpenCV Mat
    cv::Mat ncnn_output_image(out.h, out.w, CV_8UC3);
    out.to_pixels(ncnn_output_image.data, ncnn::Mat::PIXEL_RGB);

    // Convert to float
    resized_frame.convertTo(resized_frame, CV_32FC3, 1.0 / 255.0);
    frame.convertTo(frame, CV_32FC3, 1.0 / 255.0);
    ncnn_output_image.convertTo(ncnn_output_image, CV_32FC3, 1.0 / 255.0);

    // Apply the guided filter
    auto result = this->gf->guidedFilter(resized_frame, ncnn_output_image, frame.rows, frame.cols);
    this->matrix_A = result.first;
    this->matrix_B = result.second;

    // Calculate the output
    enhanced_frame = this->matrix_A.mul(frame) + this->matrix_B;

    // Convert the final output back to 8-bit
    enhanced_frame.convertTo(enhanced_frame, CV_8UC3, 255.0);

    // Convert RGB to BGR
    cv::cvtColor(enhanced_frame, enhanced_frame, cv::COLOR_RGB2BGR);
//    std::cout << "Guided Filter" << std::endl;
}
// Method to enhance the frame using the guided filter
void VideoEnhancementPipeline::enhanceFrameGuidedFilter(cv::Mat frame, cv::Mat &enhanced_frame)
{
    // Start Preprocessing
    cv::cvtColor(frame, frame, cv::COLOR_BGR2RGB);

    // Normalize the input frame
    frame.convertTo(frame, CV_32FC3, 1.0 / 255.0);

    // Calculate the output
    enhanced_frame = this->matrix_A.mul(frame) + this->matrix_B;

    // Convert the final output back to 8-bit
    enhanced_frame.convertTo(enhanced_frame, CV_8UC3, 255.0);

    // Convert RGB to BGR
    cv::cvtColor(enhanced_frame, enhanced_frame, cv::COLOR_RGB2BGR);
}

void VideoEnhancementPipeline::enhanceFrame(const cv::Mat &frame, cv::Mat &enhanced_frame)
{
    if (this->counter % this->skipframe == 0)
    {
        enhanceFrameNCNN(frame, enhanced_frame);
        std::cout << "enhanceFrameNCNN at "<< this->counter << std::endl;
    }
    else
    {
        enhanceFrameGuidedFilter(frame, enhanced_frame);
        std::cout << "enhanceFrameGuidedFilter at "<< this->counter << std::endl;
    }
    this->counter = (this->counter + 1) % this->skipframe;
    std::cout << "this->counter "<< this->counter << std::endl;
}

// Setter for skipframe
void VideoEnhancementPipeline::setSkipFrame(int skipframe)
    {
        this->skipframe = skipframe;
    }


// Class GuidedFilter
// Constructor
GuidedFilter::GuidedFilter(int r, float eps, float alpha, float beta)
    : r(r), eps(eps), alpha(alpha), beta(beta) {}

std::pair<cv::Mat, cv::Mat> GuidedFilter::guidedFilter(const cv::Mat &I, const cv::Mat &p, int height, int width)
{
    cv::Mat mean_I, mean_p, mean_Ip, cov_Ip, mean_II, var_I, a, b, mean_a, mean_b;

    // Step 1: Calculate mean of I and p
    cv::boxFilter(I, mean_I, CV_32F, cv::Size(r, r));
    cv::boxFilter(p, mean_p, CV_32F, cv::Size(r, r));
//    NSLog(@"Here %d");
    // Step 2: Calculate mean of I*p and covariance
    cv::boxFilter(I.mul(p), mean_Ip, CV_32F, cv::Size(r, r));
    cov_Ip = mean_Ip - mean_I.mul(mean_p);

    // Step 3: Calculate variance of I
    cv::boxFilter(I.mul(I), mean_II, CV_32F, cv::Size(r, r));
    var_I = mean_II - mean_I.mul(mean_I);

    // Step 4: Calculate coefficients a and b
    a = cov_Ip / (var_I + eps);
    b = mean_p - a.mul(mean_I);

    // Step 5: Calculate mean of a and b
    cv::boxFilter(a, mean_a, CV_32F, cv::Size(r, r));
    cv::boxFilter(b, mean_b, CV_32F, cv::Size(r, r));

    // Step 6: Resize mean_a and mean_b to original image size
    cv::resize(mean_a, mean_a, cv::Size(width, height), 0, 0, cv::INTER_LINEAR);
    cv::resize(mean_b, mean_b, cv::Size(width, height), 0, 0, cv::INTER_LINEAR);

    // Adjust mean_a and mean_b
    mean_a = mean_a.mul(alpha);
    mean_b = mean_b.mul(beta);

    // Return the pair of results
    return std::make_pair(mean_a, mean_b);
}


void testGuidedFilter() {
    // Initialize parameters for GuidedFilter
    int r = 5;              // Radius
    float eps = 0.01f;      // Regularization parameter
    float alpha = 1.0f;     // Alpha adjustment parameter
    float beta = 0.5f;      // Beta adjustment parameter

    // Create dummy input matrices
    int width = 100;
    int height = 100;
    cv::Mat I = cv::Mat::ones(height, width, CV_32F);   // Example input image I
    cv::Mat p = cv::Mat::ones(height, width, CV_32F);   // Example guidance image p

    // Initialize the GuidedFilter
    GuidedFilter filter(r, eps, alpha, beta);

    // Apply the guided filter
    auto result = filter.guidedFilter(I, p, height, width);

    // Extract results
    cv::Mat mean_a = result.first;
    cv::Mat mean_b = result.second;

    // Validate the result
    if (mean_a.size() == cv::Size(width, height) && mean_b.size() == cv::Size(width, height)) {
        std::cout << "Test passed: Output size matches input size." << std::endl;
    } else {
        std::cout << "Test failed: Output size does not match input size." << std::endl;
    }
}


const char* check_version_ncnn_wrapper(){
    ncnn::Net net;
    const char* version = "56";
    std::string version_info = "Version NCNN from wrapper " + std::string(version);
    // Dynamically allocate memory for the result
    char* result = new char[version_info.length() + 1];
    std::strcpy(result, version_info.c_str());
    
    testGuidedFilter(); // okay
    
    return result ;
}

