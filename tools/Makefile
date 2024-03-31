CXX=g++
CXXFLAGS=-Wall -Wextra -std=c++11
TARGET=adftrack

all: $(TARGET)

$(TARGET): adftrack.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -f $(TARGET)
