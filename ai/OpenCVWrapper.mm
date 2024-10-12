#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"
#import "ncnnWrapper.hpp"
#import "ncnn/ncnn/net.h"
#import <chrono>
/*
 * add a method convertToMat to UIImage class
 */
@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists {
    if (self.imageOrientation == UIImageOrientationRight) {	
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat, alphaExists);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}
@end

@implementation OpenCVWrapper

+ (NSString *)getOpenCVVersion {
    return [NSString stringWithFormat:@"OpenCV loaded and its Version %s",  CV_VERSION];
}

+ (UIImage *)grayscaleImg:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    cv::Mat gray;
    
    NSLog(@"channels = %d", mat.channels());

    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, cv::COLOR_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    UIImage *grayImg = MatToUIImage(gray);
    return grayImg;
}

+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    if (mat.channels() == 4) {
        [image convertToMat: &mat :true];
    }
    
    NSLog(@"source shape = (%d, %d)", mat.cols, mat.rows);
    
    cv::Mat resized;
    
//    cv::INTER_NEAREST = 0,
//    cv::INTER_LINEAR = 1,
//    cv::INTER_CUBIC = 2,
//    cv::INTER_AREA = 3,
//    cv::INTER_LANCZOS4 = 4,
//    cv::INTER_LINEAR_EXACT = 5,
//    cv::INTER_NEAREST_EXACT = 6,
//    cv::INTER_MAX = 7,
//    cv::WARP_FILL_OUTLIERS = 8,
//    cv::WARP_INVERSE_MAP = 16
    
    cv::Size size = {width, height};
    
    cv::resize(mat, resized, size, 0, 0, interpolation);
    
    NSLog(@"dst shape = (%d, %d)", resized.cols, resized.rows);
    
    UIImage *resizedImg = MatToUIImage(resized);
    
    return resizedImg;

}

@end


cv::Mat matWithImage(UIImage *image) {
    cv::Mat dst;
    UIImageToMat(image, dst);
    return dst;
}

UIImage *imageWithCVMat(const cv::Mat &source) {
    return MatToUIImage(source);
}

void enhanceFrameNCNN(cv::Mat frame, cv::Mat &enhanced_frame, ncnn::Net &net)
{
    const float scal[] = {0.003915, 0.003915, 0.003915};
    const float scal2[] = {255, 255, 255};
    ncnn::Extractor extractor = net.create_extractor();
    
    int r = 24;
    float eps = 0.00000001f;
    float alpha = 1.f;
    float beta = 1.f;
    
    int input_width = 1920/12;
    int input_height = 1080/12;
   
    // Initialize the GuidedFilter
    GuidedFilter gf(r, eps, alpha, beta);

    cv::cvtColor(frame, frame, cv::COLOR_RGBA2RGB);

    // Resize the frame to the desired size
    cv::Mat resized_frame;
    cv::resize(frame, resized_frame, cv::Size(input_width, input_height));

    // Convert the frame to ncnn Mat format
    ncnn:: Mat in = ncnn::Mat::from_pixels(resized_frame.data,
                                           ncnn::Mat::PIXEL_RGB,
                                           resized_frame.cols,
                                           resized_frame.rows);

    // Normalize the input frame to the range of 0-1
    in.substract_mean_normalize(0, scal); // 0-255  -->  0-1

    // Perform Inference
    extractor.input("in0", in);
    ncnn:: Mat out;
    extractor.extract("out0", out);

    std::cout << "Done Inference" << std::endl;

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
    auto result = gf.guidedFilter(resized_frame, ncnn_output_image, frame.rows, frame.cols);
    
    cv::Mat matrix_A = result.first;
    cv::Mat matrix_B = result.second;

    // Calculate the output
    enhanced_frame = matrix_A.mul(frame) + matrix_B;

    // Convert the final output back to 8-bit
    enhanced_frame.convertTo(enhanced_frame, CV_8UC3, 255.0);

     
    cv::cvtColor(enhanced_frame, enhanced_frame, cv::COLOR_RGB2RGBA);
    std::cout << "Guided Filter" << std::endl;
}


#import "ncnn/ncnn/net.h"

@implementation ModelWrapper {
ncnn::Net net;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize NCNN
    }
    return self;
}

- (BOOL)loadModel:(NSString *)paramPath binPath:(NSString *)binPath {
    // Convert NSString to std::string
    std::string param_path = [paramPath UTF8String];
    std::string bin_path = [binPath UTF8String];
    
    // Load the NCNN model
    if (net.load_param(param_path.c_str()) != 0 || net.load_model(bin_path.c_str()) != 0) {
        NSLog(@"Failed to load model");
        return NO;
    }
    return YES;
}

- (NSDictionary *)prewithResize:(UIImage *)inputImage {
    /*
     FOR reseffnet_gan_div12_core_mode only
     */
    auto start = std::chrono::high_resolution_clock::now();
    // conver UIImage to cv::Mat
    cv::Mat src = matWithImage(inputImage);
    // Preprocessing
    // IU image in RGBA, model needs RGB;    
    cv::cvtColor(src, src, cv::COLOR_RGBA2RGB);

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
    cv::cvtColor(enhanced_img, enhanced_img, cv::COLOR_RGB2RGBA);
    
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end - start;
    NSLog(@"Execution Time: %.2f ms in C++",elapsed_post.count()*1000);
    
    const char* version = check_version_ncnn_wrapper();
    NSLog(@"%s", version);
    free((void*)version);
    
    return @{
            @"image": imageWithCVMat(enhanced_img), // convert back to UIImage
            @"executionTime": @(elapsed_post.count() * 1000) // Convert seconds to milliseconds
        };
}

- (NSDictionary *)predict:(UIImage *)inputImage {
    /*
     For other models without resize
     */
    auto start = std::chrono::high_resolution_clock::now();
    // conver UIImage to cv::Mat
    cv::Mat src = matWithImage(inputImage);
    // Preprocessing
    // opencv image in bgr, model needs rgb;
    cv::cvtColor(src, src, cv::COLOR_RGBA2RGB);
    // Convert image data to ncnn format
    ncnn::Mat in = ncnn::Mat::from_pixels(src.data,
                                          ncnn::Mat::PIXEL_RGB,
                                          src.cols, src.rows);
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
    cv::Mat enhanced_img;
    cv::cvtColor(ncnn_output_image, enhanced_img, cv::COLOR_RGB2RGBA);    
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end - start;
    NSLog(@"Execution Time: %.2f ms in C++",elapsed_post.count()*1000);
    
    return @{
            @"image": imageWithCVMat(enhanced_img),// convert back to UIImage
            @"executionTime": @(elapsed_post.count() * 1000) // Convert seconds to milliseconds
        };
}

- (NSDictionary *)predictGF:(NSArray<UIImage *> *)inputFrames {
    /*
     FOR convnext_tiny.ncnn with Resize as the same as convnext_tiny_div12.ncnn
     */
    auto start_total = std::chrono::high_resolution_clock::now();
    NSLog(@"Here ");
    std::vector<cv::Mat> enhanced_frames;
    
    //Convert NSArray<UIImage *> to std<Vector><cv::Mat>
    std::vector<cv::Mat> frames;
    for (UIImage *UI_image in inputFrames) {
        cv::Mat mat = matWithImage(UI_image);
        frames.push_back(mat);        
    }
    NSLog(@"extracted frame successfully ",frames.size());
    const float scal[] = {0.003915, 0.003915, 0.003915};
    const float scal2[] = {255, 255, 255};
    cv::Mat mean_a, mean_b;
    cv::Mat final_output;

    int skip_frame = 50;
    int r = 24;
    float eps = 0.00000001f;
    float alpha = 1.f;
    float beta = 1.f;
    
    int input_width = 1920/12;
    int input_height = 1080/12;
   
    // Initialize the GuidedFilter
    GuidedFilter gf(r, eps, alpha, beta);
    
    auto start = std::chrono::high_resolution_clock::now(); // Initialization
    auto end = std::chrono::high_resolution_clock::now();   // Initialization

    std::chrono::duration<double> preprocessed_time = end - end;
    std::chrono::duration<double> postprocessed_time = end - end;
    std::chrono::duration<double> inference_time = end - end;
    std::chrono::duration<double> guided_filter_time = end - end;
    std::chrono::duration<double> transformation_time = end - end;
    
    for (size_t i = 0; i < frames.size(); ++i)
    {
        if (i % skip_frame == 0) // First frame of the batch will be passed through the ncnn model
        {
            // Start preprocessing
            start = std::chrono::high_resolution_clock::now();

            // Preprocess the frames
            cv::Mat frame = frames[i];
            cv::cvtColor(frame, frame, cv::COLOR_RGBA2RGB);

            // Resize the frame to the desired size
            cv::Mat resized_frame;
            cv::resize(frame, resized_frame, cv::Size(input_width,input_height));

            ncnn::Extractor extractor = net.create_extractor();

            // Convert the frame to ncnn Mat format
            ncnn::Mat in = ncnn::Mat::from_pixels(resized_frame.data, ncnn::Mat::PIXEL_RGB, resized_frame.cols, resized_frame.rows);

            // Normalize the input frame to the range of 0-1
            in.substract_mean_normalize(0, scal); // 0-255  -->  0-1

            // End preprocessing
            end = std::chrono::high_resolution_clock::now();
            preprocessed_time += end - start;

            // Start Inferencing
            start = std::chrono::high_resolution_clock::now();

            // Perform Inference
            extractor.input("in0", in);
            ncnn::Mat out;
            extractor.extract("out0", out);
            
            // Denormalize the output
            out.substract_mean_normalize(0, scal2);

            // Stop measuring time
            end = std::chrono::high_resolution_clock::now();

            // Calculate and print inference time
            inference_time += end - start;

            // Convert NCNN output back to OpenCV Mat
            cv::Mat ncnn_output_image(out.h, out.w, CV_8UC3);
            out.to_pixels(ncnn_output_image.data, ncnn::Mat::PIXEL_RGB);
           
            // Start guided filtering
            start = std::chrono::high_resolution_clock::now();

            // Convert to float
            resized_frame.convertTo(resized_frame, CV_32FC3, 1.0 / 255.0);
            frame.convertTo(frame, CV_32FC3, 1.0 / 255.0);
            ncnn_output_image.convertTo(ncnn_output_image, CV_32FC3, 1.0 / 255.0);
    
            // Apply the guided filter
            auto result = gf.guidedFilter(resized_frame, ncnn_output_image, frame.rows, frame.cols);
            mean_a = result.first;
            mean_b = result.second;
            
            // Stop measuring time
            end = std::chrono::high_resolution_clock::now();
            guided_filter_time += end - start;

            // Start Transformation
            start = std::chrono::high_resolution_clock::now();

            // Calculate the output
            final_output = mean_a.mul(frame) + mean_b;

            end = std::chrono::high_resolution_clock::now();
            transformation_time += end - start;

            // Start Postprocessing
            start = std::chrono::high_resolution_clock::now();

            // Convert the final output back to 8-bit
            final_output.convertTo(final_output, CV_8UC3, 255.0);

            // Convert RGB to BGR
            cv::cvtColor(final_output, final_output, cv::COLOR_RGB2RGBA);

            // End Postprocessing
            end = std::chrono::high_resolution_clock::now();
            postprocessed_time += end - start;
            NSLog(@"iter: %d",i );

        }
        else // The other frames in the batch will be applied linear transformation
        {
            // Start Preprocessing
            start = std::chrono::high_resolution_clock::now();

            cv::Mat frame = frames[i];
            cv::cvtColor(frame, frame, cv::COLOR_RGBA2RGB);

            // Normalize the input frame
            frame.convertTo(frame, CV_32FC3, 1.0 / 255.0);

            // End Preprocessing
            end = std::chrono::high_resolution_clock::now();
            preprocessed_time += end - start;

            // Start Transformation
            start = std::chrono::high_resolution_clock::now();

            // Calculate the output
            final_output = mean_a.mul(frame) + mean_b;

            // End Transformation
            end = std::chrono::high_resolution_clock::now();
            transformation_time += end - start;

            // Start Postprocessing
            start = std::chrono::high_resolution_clock::now();

            // Convert the final output back to 8-bit
            final_output.convertTo(final_output, CV_8UC3, 255.0);

            // Convert RGB to BGR
            cv::cvtColor(final_output, final_output, cv::COLOR_RGB2RGBA);

            // End Postprocessing
            end = std::chrono::high_resolution_clock::now();
            postprocessed_time += end - start;
            
        }

        // Save the enhanced frame to enhanced_frames
        enhanced_frames.push_back(final_output.clone());
    }
    
        // Print out the time
    std::cout << "Total Preprocessing Time: " << preprocessed_time.count() << " seconds" << std::endl;
    std::cout << "Total Inference Time: " << inference_time.count() << " seconds" << std::endl;
    std::cout << "Total Guided Filter Time: " << guided_filter_time.count() << " seconds" << std::endl;
    std::cout << "Total Transformation Time: " << transformation_time.count() << " seconds" << std::endl;
    std::cout << "Total Postprocessing Time: " << postprocessed_time.count() << " seconds" << std::endl;
    // TOTAL TIME
    std::cout << "TOTAL: " << preprocessed_time.count() + inference_time.count() + guided_filter_time.count() + transformation_time.count() + postprocessed_time.count() << " seconds" << std::endl;
    
    NSMutableArray<UIImage *> *enhancedFrames = [NSMutableArray arrayWithCapacity:enhanced_frames.size()];
    for (const cv::Mat& enhanced_frame: enhanced_frames){
        UIImage *processed_image = imageWithCVMat(enhanced_frame);
        [enhancedFrames addObject:processed_image];
    }

    auto end_total = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end_total - start_total;
    NSLog(@"Execution Time: %.2f ms in C++",elapsed_post.count()*1000);
        
    return @{
            @"frames": enhancedFrames, // convert back to UIImage - origin : inputFrames
            @"executionTime": @(elapsed_post.count() * 1000) // Convert seconds to milliseconds
        };
}

- (NSDictionary *)predictGFwithframes:(NSArray<UIImage *> *)inputFrames {
    /*
     FOR convnext_tiny.ncnn with Resize as the same as convnext_tiny_div12.ncnn
     */
    auto start_total = std::chrono::high_resolution_clock::now();
    NSMutableArray<UIImage *> *processedFrames = [NSMutableArray array];
    int skipFrame = 30;
    VideoEnhancementPipeline vep(net);
    vep.setSkipFrame(skipFrame);
    
    for (UIImage *inputFrame in inputFrames) {
        //conver UIImage to cv::Mat
        cv::Mat src = matWithImage(inputFrame);
        cv::Mat enhanced_frame;
        vep.enhanceFrame(src, enhanced_frame);
        UIImage *processedFrame = imageWithCVMat(enhanced_frame);
        [processedFrames addObject:processedFrame];
    }
    
    auto end_total = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_post = end_total - start_total;
    NSLog(@"Execution Time: %.2f ms in C++",elapsed_post.count()*1000);
    return @{
            @"frames": processedFrames, //  origin : inputFrames
            @"executionTime": @(elapsed_post.count() * 1000) // Convert seconds to milliseconds
        };
}

@end

