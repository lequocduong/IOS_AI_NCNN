#include "ir_model.h"
#include <opencv2/opencv.hpp>

using namespace AIBox;

IRModel::IRModel(int upscale, int tile)
    : BaseModel({0, 0, 0}, {1, 1, 1}),
      upscale_(upscale),
      window_size_(64),
      tile_(tile),
      tile_pad_(32)
{
}

cv::Mat IRModel::preprocess(const cv::Mat &im0, cv::Size &size)
{
    cv::Mat result;
    int im_wid = im0.cols;
    int im_hei = im0.rows;

    cv::Mat im = im0;

    if (!is_dynamic_) {
        float ratio = static_cast<float>(im_wid) / static_cast<float>(im_hei);
        if (ratio > 1.0) {
            im_wid = input_size_.width;
            im_hei = static_cast<int>(input_size_.width / ratio);
        } else {
            im_hei = input_size_.height;
            im_wid = static_cast<int>(input_size_.height * ratio);
        }
        cv::resize(im0, im, cv::Size(im_wid, im_hei));
    }

    size = {im_wid, im_hei};

    int pad_w = ceil(1.f * im_wid / window_size_) * window_size_ - im_wid;
    int pad_h = ceil(1.f * im_hei / window_size_) * window_size_ - im_hei;
    cv::copyMakeBorder(im, result, 0, pad_h, 0, pad_w, cv::BORDER_CONSTANT, {0});
    return result;
}

cv::Mat IRModel::predict(const cv::Mat &im0, TimeCost &time_cost)
{
    timer_.reset();

    int im_wid = im0.cols;
    int im_hei = im0.rows;

    std::vector<cv::Mat> inputs;
    cv::Size size;
    inputs.push_back(preprocess(im0, size));
    im_wid = size.width;
    im_hei = size.height;

    forward(inputs);

    int out_im_hei = im_hei * upscale_;
    int out_im_wid = im_wid * upscale_;

#if defined(ONNXRUNTIME)
    const auto *raw_output = pred_[0].GetTensorData<float>();
    auto output_shape = pred_[0].GetTensorTypeAndShapeInfo().GetShape();

#elif defined(OPENVINO)
    const ov::Tensor &output_tensor = infer_request_.get_output_tensor();
    const auto *raw_output = output_tensor.data<float>();
    auto output_shape = output_tensor.get_shape();
#endif

    int ow = output_shape[3];
    int oh = output_shape[2];
    int owh = ow * oh;

    cv::Mat channelR(oh, ow, CV_32FC1, (void*)(raw_output));
    cv::Mat channelG(oh, ow, CV_32FC1, (void*)(raw_output + owh));
    cv::Mat channelB(oh, ow, CV_32FC1, (void*)(raw_output + 2 * owh));

    std::vector<cv::Mat> channels = {channelB, channelG, channelR};
    cv::Mat result;
    cv::merge(channels, result);
    result({0, out_im_hei}, {0, out_im_wid}).convertTo(result, CV_8UC3, 255.0, 0);

    post_cost_ = timer_.elapsed();
    time_cost.pre = pre_cost_;
    time_cost.post = post_cost_;
    time_cost.infer = infer_cost_;

    return result;
}