#include "mex.h"
#include "stdint.h"
#include <windows.h>
#include <ViGEm/Client.h>

// Define command enumerations
#define CMD_CLEANUP 0
#define CMD_INIT    1
#define CMD_SENDALL 2
#define CMD_SENDBTN 3

// # Compiling #
// This gamepad depends on the excellent ViGEmBus/ViGEmClient libraries. You will need to first install the ViGEmBus / client libraries and link against them to compile this mex file successfully.  

// 0. Download the pre-compiled installer for ViGEmBus (https://github.com/nefarius/ViGEmBus/releases/download/v1.22.0/ViGEmBus_1.22.0_x64_x86_arm64.exe) and follow the instructions.
// 1. Clone ViGEmClient from https://github.com/nefarius/ViGEmClient
// 2. Use CMake with VS2022 generator:
//    ```batch
//    git clone https://github.com/nefarius/ViGEmClient
//    cd ViGEmClient
//    mkdir build
//    cd build
//    cmake .. -G "Visual Studio 17 2022" -A x64 -DBUILD_SHARED_LIBS=ON
//    ```
// 3. Open the VS2022 solution that was generated inside of ~/build, using Visual Studio. Switch to `release` mode. Right click "ALL_BUILD" and click "Build". Now, in ~/build/Release, you should see ViGEmClient.lib (static library) and ViGEmClient.dll (dynamic link library).  
//      + _Alternatively, from the same VS2022 Developer Command Prompt in Step 2, run the following:_
//      ```batch
//      msbuild ViGEmClient.sln /p:Configuration=Release /p:Platform=x64
//      ```
// 4. From a MATLAB terminal, using the same generator you used when compiling the ViGEmClient.lib and ViGEmClient.dll libraries:  
// ```
//    mex -v -I"C:\MyRepos\Libraries\ViGEmClient\include" ...
//        -L"C:\MyRepos\Libraries\ViGEmClient\build\Release" ...
//        -lViGEmClient ...
//        -lSetupapi ...
//        vigem_gamepad.c
// ```
// _(Note that this example assumes ViGEmClient was cloned to C:\MyRepos\Libraries\ViGEmClient, so modify that part as necessary)._ 
//
//
// # Example Usage #
//
// vigem_gamepad('init'); % Initialize the virtual gamepad
// 
// % Press "A" button (XINPUT_GAMEPAD_A = 0x1000)
// vigem_gamepad('send', 0x1000, 0, 0, 0, 0); % A button pressed
// pause(1); % Hold for 1 second
// 
// vigem_gamepad('send', 0, 0, 0, 0, 0); % Release all buttons
// vigem_gamepad('cleanup'); % Clean up the gamepad

// Global variables to store the client and controller handles
static PVIGEM_CLIENT client = NULL;
static PVIGEM_TARGET target = NULL;
static bool isGamepadInitialized = false; // Track initialization state

// Initialize the ViGEm Client and create a virtual Xbox controller
void initializeGamepad() {
    if (client != NULL && target != NULL) {
        mexErrMsgIdAndTxt("MATLAB:gamepad:alreadyInitialized", "Gamepad already initialized.");
    }

    client = vigem_alloc();
    if (client == NULL) {
        mexErrMsgIdAndTxt("MATLAB:gamepad:initFailed", "Failed to allocate ViGEm client.");
    }

    if (!VIGEM_SUCCESS(vigem_connect(client))) {
        mexErrMsgIdAndTxt("MATLAB:gamepad:initFailed", "Failed to connect to ViGEmBus.");
    }

    target = vigem_target_x360_alloc();
    if (!VIGEM_SUCCESS(vigem_target_add(client, target))) {
        mexErrMsgIdAndTxt("MATLAB:gamepad:initFailed", "Failed to add virtual Xbox controller.");
    }
    isGamepadInitialized = true;
}

// Send input to the virtual gamepad
void sendGamepadInput(uint16_t buttons, int8_t leftX, int8_t leftY, int8_t rightX, int8_t rightY) {
    XUSB_REPORT report = { 0 };

    // Set buttons and joystick values
    report.wButtons = buttons;
    report.bLeftTrigger = 0; // No trigger pressed
    report.bRightTrigger = 0;
    report.sThumbLX = leftX * 256; // Convert to 16-bit
    report.sThumbLY = leftY * 256;
    report.sThumbRX = rightX * 256;
    report.sThumbRY = rightY * 256;

    // Update the virtual controller
    vigem_target_x360_update(client, target, report);
}

// Clean up the gamepad and release resources
void cleanupGamepad() {
    if (!isGamepadInitialized) {
        mexWarnMsgIdAndTxt("MATLAB:gamepad:notInitialized", "No gamepad to clean up.");
        return;
    }
    if (target) {
        vigem_target_remove(client, target);
        vigem_target_free(target);
    }
    if (client) {
        vigem_disconnect(client);
        vigem_free(client);
    }
    target = NULL;
    client = NULL;
    isGamepadInitialized = false;
}

void cleanupOnExit() {
    cleanupGamepad();
}

void printHelp() {
    mexPrintf("<strong>vigem_gamepad</strong>: Virtual Gamepad Emulation with ViGEm\n");
    mexPrintf("=========================\n");
    mexPrintf("   Usage Instructions   \n");
    mexPrintf("=========================\n");
    mexPrintf("Usage:\n");
    mexPrintf("  vigem_gamepad(command, ...)\n\n");
    mexPrintf("Commands:\n\n\n");

    // CMD_INIT
    mexPrintf("  <strong>CMD_INIT</strong> (1): Initialize the virtual gamepad.\n");
    mexPrintf("    Example: vigem_gamepad(1);\n\n");

    // CMD_SENDBTN
    mexPrintf("  <strong>CMD_SENDBTN</strong> (3): Send a button press.\n");
    mexPrintf("    Inputs: button_code\n");
    mexPrintf("    Example: vigem_gamepad(3, 0x1000); %% Press 'A' button\n\n");
    mexPrintf("    Button Mapping:\n");
    mexPrintf("    -------------------------------------\n");
    mexPrintf("    | <strong>Button            | Code (Hex)</strong>    |\n");
    mexPrintf("    -------------------------------------\n");
    mexPrintf("    | A                | 0x1000        |\n");
    mexPrintf("    | B                | 0x2000        |\n");
    mexPrintf("    | X                | 0x4000        |\n");
    mexPrintf("    | Y                | 0x8000        |\n");
    mexPrintf("    | LB               | 0x0100        |\n");
    mexPrintf("    | RB               | 0x0200        |\n");
    mexPrintf("    | Back             | 0x0020        |\n");
    mexPrintf("    | Start            | 0x0010        |\n");
    mexPrintf("    | Left Thumb       | 0x0040        |\n");
    mexPrintf("    | Right Thumb      | 0x0080        |\n");
    mexPrintf("    | D-Pad Up         | 0x0001        |\n");
    mexPrintf("    | D-Pad Down       | 0x0002        |\n");
    mexPrintf("    | D-Pad Left       | 0x0004        |\n");
    mexPrintf("    | D-Pad Right      | 0x0008        |\n");
    mexPrintf("    -------------------------------------\n\n");

    // CMD_SENDALL
    mexPrintf("  <strong>CMD_SENDALL</strong> (2): Send button and joystick inputs.\n");
    mexPrintf("    Inputs: button_code, leftX, leftY, rightX, rightY\n");
    mexPrintf("    Example: vigem_gamepad(2, 0x1000, 50, -50, 25, -25);\n\n");
    mexPrintf("    Expected Input Ranges:\n");
    mexPrintf("    --------------------------------------------------\n");
    mexPrintf("    | Input        | Range         | Type            |\n");
    mexPrintf("    --------------------------------------------------\n");
    mexPrintf("    | button_code  | 0x0000-0xFFFF | uint16_t        |\n");
    mexPrintf("    | leftX        | -128 to 127   | int8_t          |\n");
    mexPrintf("    | leftY        | -128 to 127   | int8_t          |\n");
    mexPrintf("    | rightX       | -128 to 127   | int8_t          |\n");
    mexPrintf("    | rightY       | -128 to 127   | int8_t          |\n");
    mexPrintf("    --------------------------------------------------\n");
    mexPrintf("    Notes:\n");
    mexPrintf("    - leftX, leftY control the left joystick.\n");
    mexPrintf("    - rightX, rightY control the right joystick.\n");
    mexPrintf("    - Joystick values represent the percentage of axis movement:\n");
    mexPrintf("      - 0 is centered.\n");
    mexPrintf("      - Positive values move right/up.\n");
    mexPrintf("      - Negative values move left/down.\n");
    mexPrintf("      - Max value (127 or -128) represents full movement.\n\n");

    // CMD_CLEANUP
    mexPrintf("  <strong>CMD_CLEANUP</strong> (0): Clean up and release resources.\n");
    mexPrintf("    Example: vigem_gamepad(0);\n\n");

    mexPrintf("<strong>Notes</strong>:\n");
    mexPrintf("  - Ensure ViGEmBus and ViGEmClient are properly installed.\n");
    mexPrintf("  - Use CMD_INIT before sending inputs.\n");
    mexPrintf("  - Call CMD_CLEANUP to release resources when done.\n");
    return;
}

// MEX function entry point
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    static bool mexInitialized = false;
    if (!mexInitialized) {
        mexAtExit(cleanupGamepad); // Register cleanup handler
        mexInitialized = true;
    }

    if (nrhs == 0) {
        printHelp();
        return;
    }

    // Get the command as an integer
    uint8_t command = (uint8_t)mxGetScalar(prhs[0]);
    uint16_t buttons = 0;

    switch (command) {
        case CMD_INIT:
            initializeGamepad();
            break;

        case CMD_SENDBTN:
            buttons = (uint16_t)mxGetScalar(prhs[1]);
            sendGamepadInput(buttons, 0, 0, 0, 0);
            break;

        case CMD_SENDALL:
            if (nrhs != 6) {
                printHelp();
                mexErrMsgIdAndTxt("MATLAB:gamepad:invalidNumInputs", "Five inputs required for 'send'.");
            }
            buttons = (uint16_t)mxGetScalar(prhs[1]);
            int8_t leftX = (int8_t)mxGetScalar(prhs[2]);
            int8_t leftY = (int8_t)mxGetScalar(prhs[3]);
            int8_t rightX = (int8_t)mxGetScalar(prhs[4]);
            int8_t rightY = (int8_t)mxGetScalar(prhs[5]);
            sendGamepadInput(buttons, leftX, leftY, rightX, rightY);
            break;

        case CMD_CLEANUP:
            cleanupGamepad();
            break;

        default:
            printHelp();
            mexErrMsgIdAndTxt("MATLAB:gamepad:invalidCommand", "Invalid command.");
    }
}