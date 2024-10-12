//
//  ncnnProcessing.cpp
//  FastAI
//
//  Created by Puwell on 16/9/24.
//

#include "ncnnProcessing.hpp"
#include <iostream>
#include "ncnn/ncnn/net.h"
#include "ncnnWrapper.hpp"
// Constructor
ModelWrapper::ModelWrapper(): vep(net) {
    
    // Skip frame value, this can be customized
    int skipFrame = 30;
    // Set skip frame for the pipeline
    vep.setSkipFrame(skipFrame);

}

// Load the NCNN model
bool ModelWrapper::loadModel(const std::string& paramPath, const std::string& binPath) {
    ncnn::Net net;
    // Load the NCNN model
    if (this->net.load_param(paramPath.c_str()) != 0 || this->net.load_model(binPath.c_str()) != 0) {
        std::cerr << "Failed to load model" << std::endl;
        return false;
    }
    return true;
}



// Preprocess with resize and perform inference
std::pair<cv::Mat, double> ModelWrapper::preWithResize(const cv::Mat& inputImage) {
    /*
     FOR reseffnet_gan_div12_core_mode only
     */
    auto start = std::chrono::high_resolution_clock::now();
    // Preprocessing    
    cv::Mat src;
    cv::cvtColor(inputImage, src, cv::COLOR_BGR2RGB);

    //Downscale the image by a factor of 12
    cv::Mat downscaled_image;
        cv::resize(src, downscaled_image, cv::Size(), 1.0 / 12.0, 1.0 / 12.0, cv::INTER_LINEAR);

    // Convert image data to ncnn format
    ncnn::Mat in = ncnn::Mat::from_pixels(downscaled_image.data,
                                          ncnn::Mat::PIXEL_RGB,
                                          downscaled_image.cols, downscaled_image.rows);

    // Data preprocessing (normalization)
    const float scal[] = {0.003915, 0.003915, 0.003915};
    in.substract_mean_normalize(0, scal); // 0-255  -->  0-1

    // Perform inference
    ncnn::Extractor ex = net.create_extractor();
    ex.input("in0", in);
    ncnn::Mat out;
    ex.extract("out0", out);

    // Post processing
    // Denormalize the ncnn output to the range of 0-255
    const float scal2[] = {255, 255, 255};
    out.substract_mean_normalize(0, scal2);
    // Convert ncnn output back to OpenCV format
    cv::Mat ncnn_output_image(out.h, out.w, CV_8UC3);
    out.to_pixels(ncnn_output_image.data, ncnn::Mat::PIXEL_RGB);
    //Upscale the output image by a factor of 12
    cv::Mat upscaled_image;
    cv::resize(ncnn_output_image, upscaled_image, src.size(), 0, 0, cv::INTER_LINEAR);
    
    // Add the original image to the upscaled image
    cv::Mat enhanced_img;
    cv::addWeighted(src, 1.0, upscaled_image, 1.0, 0.0, enhanced_img);
    cv::cvtColor(enhanced_img, enhanced_img, cv::COLOR_RGB2BGR);
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end - start;
    std::cerr << "Execution Time: %.2f ms in C++: "<<  elapsed_post.count()*1000 << std::endl;
 
    // Return the processed image and the execution time in milliseconds
    return {enhanced_img, elapsed_post.count() * 1000}; // Convert seconds to milliseconds
}



// Perform prediction on a series of frames
std::pair<cv::Mat , double> ModelWrapper::predictNCNNWithFrame(const cv::Mat& inputFrame) {   
    
    auto start = std::chrono::high_resolution_clock::now();
    cv::Mat enhanced_frame;
    vep.enhanceFrameNCNN(inputFrame, enhanced_frame);
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end - start;

    // Return processed frames and the execution time
    return {enhanced_frame, elapsed_post.count() * 1000}; // Execution time in milliseconds
}

// Perform prediction on a series of frames
std::pair<cv::Mat , double> ModelWrapper::predictGFwithFrame(const cv::Mat& inputFrame) {
    
    auto start = std::chrono::high_resolution_clock::now();
    
    cv::Mat enhanced_frame;
    vep.enhanceFrame(inputFrame, enhanced_frame);
    auto end = std::chrono::high_resolution_clock::now();
    
    std::chrono::duration<double> elapsed_post = end - start;

    // Return processed frames and the execution time
    return {enhanced_frame, elapsed_post.count() * 1000}; // Execution time in milliseconds
}
