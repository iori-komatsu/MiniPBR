MakeLUT.exe: MakeLUT.cpp
	g++ \
		-std=c++17 \
		-Wall -Wextra \
		-O2 -fno-strict-aliasing \
		--include-directory ../../Vendor/stb \
		--include-directory ../../Vendor/glm \
		-o $@ \
		$<
