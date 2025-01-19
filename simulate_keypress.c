#include "mex.h"
#include <windows.h>

// To compile: `mex simulate_keypress.c`
// Usage: simulate_keypress('a', 1); % Press and hold the "A" key
//        simulate_keypress('a', 0); % Release the "A" key

// Function to simulate a key event
void simulateKeyEvent(char key, int action) {
    INPUT input;
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = key; // Virtual Key Code for the key
    input.ki.dwFlags = (action == 1) ? 0 : KEYEVENTF_KEYUP; // 0 for keydown, KEYEVENTF_KEYUP for keyup
    input.ki.time = 0;
    input.ki.dwExtraInfo = 0;

    // Send the input event
    SendInput(1, &input, sizeof(INPUT));
}

// MEX function to interface with MATLAB
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // if (nrhs != 2) {
    //     mexErrMsgIdAndTxt("MATLAB:simulate_keypress:invalidNumInputs", "Two inputs required: key and action.");
    // }

    // // Validate the key input
    // if (!mxIsChar(prhs[0])) {
    //     mexErrMsgIdAndTxt("MATLAB:simulate_keypress:inputNotString", "First input must be a single character key.");
    // }

    // // Validate the action input
    // if (!mxIsDouble(prhs[1]) || mxGetScalar(prhs[1]) < 0 || mxGetScalar(prhs[1]) > 1) {
    //     mexErrMsgIdAndTxt("MATLAB:simulate_keypress:invalidAction", "Second input must be 0 (keyup) or 1 (keydown).");
    // }

    // Extract inputs
    char key = mxArrayToUTF8String(prhs[0])[0]; // Use UTF-8 string conversion[0]; /
    int action = (int)mxGetScalar(prhs[1]); // Action: 1 for keydown, 0 for keyup

    // Simulate the key event
    simulateKeyEvent(key, action);
}
