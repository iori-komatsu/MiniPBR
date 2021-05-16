#include <algorithm>
#include <cstdlib>
#include <cstdint>
#include <iostream>
#include <vector>
#include <cmath>
using namespace std;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#pragma GCC diagnostic ignored "-Wsign-compare"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>
#include <glm/glm.hpp>

#pragma GCC diagnostic pop

constexpr double PI = 3.14159265359;
constexpr double TWO_PI = 2*PI;

glm::f64vec3 linear_to_srgb(glm::f64vec3 rgb) {
    return glm::mix(
        rgb * 12.92,
        glm::pow(rgb, glm::f64vec3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055 - 0.055,
        glm::step(0.0031308, rgb)
    );
}

double gaussian(double x, double var) {
    return exp(-(x*x)/(2*var)) / sqrt(TWO_PI*var);
}

glm::f64vec3 diffusion_profile(double dist /* in millimeters */) {
    // 出典:
    // Eugene d'Eon; David Luebke. "Chapter 14. Advanced Techniques for Realistic Real-Time Skin Rendering". GPU Gems 3.
    // https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-14-advanced-techniques-realistic-real-time-skin

    double g1 = gaussian(dist, 0.0064);
    double g2 = gaussian(dist, 0.0484);
    double g3 = gaussian(dist, 0.187);
    double g4 = gaussian(dist, 0.567);
    double g5 = gaussian(dist, 1.99);
    double g6 = gaussian(dist, 7.41);

    double r = 0.233*g1 + 0.100*g2 + 0.118*g3 + 0.113*g4 + 0.356*g5 + 0.078*g6;
    double g = 0.455*g1 + 0.336*g2 + 0.198*g3 + 0.007*g4 + 0.004*g5;
    double b = 0.649*g1 + 0.344*g2            + 0.007*g4;

    return glm::f64vec3(r, g, b);
}

glm::f64vec3 integrate_diffusion_profile(double dotNL, double curvature, int n_samples) {
    glm::f64vec3 ret(0, 0, 0);
    glm::f64vec3 z(0, 0, 0);

    double theta = acos(dotNL);
    double radius = 1.0 / curvature;

    for (int i = 0; i < n_samples; ++i) {
        double x = glm::mix(-PI, PI, double(i) / (n_samples - 1));
        glm::f64vec3 dp = diffusion_profile(2 * radius * sin(x / 2));
        ret += max(0.0, cos(theta + x)) * dp;
        z += dp;
    }

    return ret / z;
}

glm::f64vec3 calc(int x, int y, int w, int h, int n_samples) {
    double dotNL = glm::mix(-1.0, 1.0, double(x)/w);
    double curvature = glm::mix(0.0, 1.0, (y+0.5)/h);
    glm::f64vec3 c = integrate_diffusion_profile(dotNL, curvature, n_samples);
    return linear_to_srgb(c);
}

uint8_t round_to_uint8(double x) {
    return uint8_t(255.0 * x + 0.5);
}

void make_lut(int w, int h, int n_samples) {
    vector<uint8_t> image(w * h * 3);

    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            auto v = calc(x, y, w, h, n_samples);
            uint8_t* pixel = &image[3*(y*w+x)];
            pixel[0] = round_to_uint8(v.x);
            pixel[1] = round_to_uint8(v.y);
            pixel[2] = round_to_uint8(v.z);
        }
    }

    int ok = stbi_write_png("LUT.png", w, h, 3, image.data(), 3 * w);
    if (!ok) {
        cerr << "Failed to write LUT.png\n";
        exit(1);
    }
}

int main(int argc, char** argv) {
    int w = 256;
    int h = 256;
    int n_samples = 4096;
    for(int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "-w") == 0) {
            ++i;
            if (i >= argc) {
                cerr << "ERROR: missing value of -w\n";
                return 2;
            }
            w = max(1, std::atoi(argv[i]));
        }
        else if (strcmp(argv[i], "-h") == 0) {
            ++i;
            if (i >= argc) {
                cerr << "ERROR: missing value of -h\n";
                return 2;
            }
            h = max(1, std::atoi(argv[i]));
        }
        else if (strcmp(argv[i], "-s") == 0) {
            ++i;
            if (i >= argc) {
                cerr << "ERROR: missing value of -s\n";
                return 2;
            }
            n_samples = max(1, std::atoi(argv[i]));
        }
    }

    make_lut(w, h, n_samples);
    return 0;
}
