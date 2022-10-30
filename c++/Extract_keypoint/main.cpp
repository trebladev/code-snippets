//
// Created by xuan on 10/30/22.
//
#include "ORBextractor.h"
#include "argparse.hpp"

int main(int argc,char **argv){
  argparse::ArgumentParser program("extractor_keypoint");
  program.add_argument("-i", "--input").help("input image");

  try {program.parse_args(argc, argv);}
  catch (const std::runtime_error& err) {std::cerr << err.what() << std::endl << program; exit(1);}
  std::string img_path;
  if(program.present("--input"))
    img_path = program.get<std::string>("--input");

  printf("input path = %s",img_path.c_str());
//  printf("hello world");
  return 0;
}
