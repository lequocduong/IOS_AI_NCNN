//
//  ncnnProcessing.hpp
//  FastAI
//
//  Created by Puwell on 16/9/24.
//

#ifndef ncnnProcessing_hpp
#define ncnnProcessing_hpp

#include <string>
#include <vector>
#include <map>
#include <opencv2/opencv.hpp> // Include if you're using OpenCV
#include "ncnn/ncnn/net.h"
#include "ncnnWrapper.hpp"

class ModelWrapper {
public:
    // Constructor
    ModelWrapper();

    // Load model method
    bool loadModel(const std::string& paramPath, const std::string& binPath);

    // Predict method
//    std::pair<std::vector<cv::Mat>, double> predictGFWithFrames(const std::vector<cv::Mat>& inputFrames) ;
    
    // For reseffnet
    std::pair<cv::Mat, double> preWithResize(const cv::Mat& inputImage);
    
    // FOr convext_tiny_div12
    std::pair<cv::Mat, double> predictNCNNWithFrame(const cv::Mat& inputFrame);
    std::pair<cv::Mat , double> predictGFwithFrame(const cv::Mat& inputFrame); //for video only

private:
    ncnn::Net net; // NCNN network instance
    VideoEnhancementPipeline vep;
};


#endif /* ncnnProcessing_hpp */
