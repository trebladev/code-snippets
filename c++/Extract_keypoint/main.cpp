//
// Created by xuan on 10/30/22.
//
#include "ORBextractor.h"
#include "argparse.hpp"
#include "opencv2/core/core.hpp"
//#include "opencv2/imgcodecs/imgcodecs.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/features2d/features2d.hpp"

#include <opencv2/imgproc/imgproc.hpp>
int main(int argc,char **argv){
  argparse::ArgumentParser program("extractor_keypoint");
  program.add_argument("-i", "--input").help("input image");

  try {program.parse_args(argc, argv);}
  catch (const std::runtime_error& err) {std::cerr << err.what() << std::endl << program; exit(1);}
  std::string img_path;
  if(program.present("--input"))
    img_path = program.get<std::string>("--input");


  printf("input path = %s",img_path.c_str());
  // Read input image
  cv::Mat input_img = cv::imread(img_path);

  std::vector<cv::KeyPoint> allkeypoint;
  cv::Mat alldesc;

  cv::cvtColor(input_img,input_img,CV_RGBA2GRAY);
  ORB_SLAM2::ORBextractor* test_extoractor = new ORB_SLAM2::ORBextractor(
      1000,
      1.2,
      8,
      20,
      8
  );

  (*test_extoractor)(
        input_img,
        cv::Mat(),
        allkeypoint,
        alldesc
        );

  cv::drawKeypoints(input_img,allkeypoint,input_img);
  cv::imshow("input_img",input_img);
  cv::waitKey(0);


//  printf("hello world");
  return 0;
}
