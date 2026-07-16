#include "mex.h"
#include <windows.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>     // malloc/free

// Compile with: 
// mex -R2018a simulate_keypress.c

// ---------- Key table ----------
typedef struct { const char* name; WORD vk; int extended; } KeySpec;
static const KeySpec KEY_TABLE[] = {
    {"Backspace", VK_BACK, 0}, {"Tab", VK_TAB, 0}, {"Enter", VK_RETURN, 0},
    {"Shift", VK_SHIFT, 0}, {"Control", VK_CONTROL, 0}, {"Alt", VK_MENU, 0},
    {"Pause", VK_PAUSE, 0}, {"CapsLock", VK_CAPITAL, 0}, {"Esc", VK_ESCAPE, 0},
    {"Escape", VK_ESCAPE, 0}, {"Space", VK_SPACE, 0},
    {"PageUp", VK_PRIOR, 0}, {"PageDown", VK_NEXT, 0},
    {"End", VK_END, 0}, {"Home", VK_HOME, 0},
    {"Left", VK_LEFT, 1}, {"Up", VK_UP, 1}, {"Right", VK_RIGHT, 1}, {"Down", VK_DOWN, 1},
    {"Insert", VK_INSERT, 1}, {"Delete", VK_DELETE, 1},
    {"LWin", VK_LWIN, 1}, {"RWin", VK_RWIN, 1}, {"Apps", VK_APPS, 1},
    {"NumLock", VK_NUMLOCK, 1}, {"PrintScreen", VK_SNAPSHOT, 0}, {"ScrollLock", VK_SCROLL, 0},
    {"Numpad0", VK_NUMPAD0, 0}, {"Numpad1", VK_NUMPAD1, 0}, {"Numpad2", VK_NUMPAD2, 0}, {"Numpad3", VK_NUMPAD3, 0},
    {"Numpad4", VK_NUMPAD4, 0}, {"Numpad5", VK_NUMPAD5, 0}, {"Numpad6", VK_NUMPAD6, 0}, {"Numpad7", VK_NUMPAD7, 0},
    {"Numpad8", VK_NUMPAD8, 0}, {"Numpad9", VK_NUMPAD9, 0}, {"Multiply", VK_MULTIPLY, 0},
    {"Add", VK_ADD, 0}, {"Subtract", VK_SUBTRACT, 0}, {"Decimal", VK_DECIMAL, 0}, {"Divide", VK_DIVIDE, 1},
    {"F1", VK_F1, 0}, {"F2", VK_F2, 0}, {"F3", VK_F3, 0}, {"F4", VK_F4, 0},
    {"F5", VK_F5, 0}, {"F6", VK_F6, 0}, {"F7", VK_F7, 0}, {"F8", VK_F8, 0},
    {"F9", VK_F9, 0}, {"F10", VK_F10, 0}, {"F11", VK_F11, 0}, {"F12", VK_F12, 0},
    {NULL, 0, 0}
};

static int iequals(const char* a, const char* b){
    while (*a && *b) {
        if (tolower((unsigned char)*a) != tolower((unsigned char)*b)) return 0;
        ++a; ++b;
    }
    return *a == 0 && *b == 0;
}

// ---------- SendInput (scan codes) ----------
static UINT send_key_event(WORD scancode, int extended, int keydown) {
    INPUT in; ZeroMemory(&in, sizeof(in));
    in.type = INPUT_KEYBOARD;
    in.ki.wVk = 0;                      // use scan code path
    in.ki.wScan = scancode;
    in.ki.dwFlags = KEYEVENTF_SCANCODE | (keydown ? 0 : KEYEVENTF_KEYUP);
    if (extended) in.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
    return SendInput(1, &in, sizeof(INPUT));
}

// ---------- Resolve key string ----------
static int resolve_key(const char* keystr, WORD* vk, WORD* sc, int* extended) {
    if (!keystr || !*keystr) return 0;

    // Named keys
    for (const KeySpec* k = KEY_TABLE; k->name; ++k) {
        if (iequals(keystr, k->name)) {
            *vk = k->vk;
            *sc = (WORD)MapVirtualKeyA(k->vk, MAPVK_VK_TO_VSC);
            *extended = k->extended;
            return 1;
        }
    }

    // Hex VK like "0x41"
    if ((keystr[0] == '0') && (keystr[1] == 'x' || keystr[1] == 'X')) {
        unsigned int v = 0;
        if (sscanf(keystr+2, "%x", &v) == 1) {
            *vk = (WORD)(v & 0xFF);
            *sc = (WORD)MapVirtualKeyA(*vk, MAPVK_VK_TO_VSC);
            *extended = (*vk == VK_LEFT || *vk == VK_RIGHT || *vk == VK_UP || *vk == VK_DOWN ||
                         *vk == VK_INSERT || *vk == VK_DELETE || *vk == VK_HOME || *vk == VK_END ||
                         *vk == VK_PRIOR || *vk == VK_NEXT || *vk == VK_RCONTROL || *vk == VK_RMENU ||
                         *vk == VK_DIVIDE || *vk == VK_NUMLOCK || *vk == VK_RWIN || *vk == VK_LWIN);
            return 1;
        }
        return 0;
    }

    // Single character (letters/digits)
    if (strlen(keystr) == 1) {
        char c = keystr[0];
        HKL layout = GetKeyboardLayout(0);
        SHORT vks = VkKeyScanExA((CHAR)c, layout);
        if (vks != -1) {
            *vk = (WORD)(vks & 0xFF);
        } else {
            if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))
                *vk = (WORD)toupper((unsigned char)c);  // 'A'..'Z' (0x41..0x5A)
            else if (c >= '0' && c <= '9')
                *vk = (WORD)c;                           // '0'..'9' (0x30..0x39)
            else
                return 0;
        }
        *sc = (WORD)MapVirtualKeyA(*vk, MAPVK_VK_TO_VSC);
        *extended = 0;
        return 1;
    }

    // Minimal VK_XXXX support
    if (_strnicmp(keystr, "VK_", 3) == 0) {
        const char* r = keystr + 3;
        if      (_stricmp(r,"LEFT")==0)  { *vk=VK_LEFT;  *extended=1; }
        else if (_stricmp(r,"RIGHT")==0) { *vk=VK_RIGHT; *extended=1; }
        else if (_stricmp(r,"UP")==0)    { *vk=VK_UP;    *extended=1; }
        else if (_stricmp(r,"DOWN")==0)  { *vk=VK_DOWN;  *extended=1; }
        else if (_stricmp(r,"SPACE")==0) { *vk=VK_SPACE; *extended=0; }
        else return 0;
        *sc = (WORD)MapVirtualKeyA(*vk, MAPVK_VK_TO_VSC);
        return 1;
    }

    return 0;
}

// ---------- Timer-queue for non-blocking key-up ----------
typedef struct {
    WORD sc;
    int  extended;
} UpArgs;

// one-shot timer callback: runs on a system worker thread
static VOID CALLBACK up_timer_cb(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
    (void)TimerOrWaitFired;
    UpArgs* a = (UpArgs*)lpParam;
    if (a) {
        send_key_event(a->sc, a->extended, 0);  // key up
        free(a);
    }
}

// We keep a single process-wide timer queue
static HANDLE g_timer_queue = NULL;

static void ensure_timer_queue(void) {
    if (g_timer_queue == NULL) {
        HANDLE tq = CreateTimerQueue();
        if (tq == NULL) {
            mexErrMsgIdAndTxt("simulate_keypress:timerQueue","CreateTimerQueue failed (err=%lu).", GetLastError());
        }
        g_timer_queue = tq;
    }
}

// ---------- UX / parsing ----------
static void print_help(void) {
    mexPrintf(
        "simulate_keypress: Simulate keyboard events on Windows (SendInput)\n"
        "==================\n"
        "Usage:\n"
        "  simulate_keypress()                             %% Show this help\n"
        "  simulate_keypress(KEY, ACTION)\n"
        "  simulate_keypress(KEY, 'tap', TAP_MS)          %% non-blocking (timer)\n"
        "\n"
        "KEY    : 'a', 'Left', 'Space', 'F5', '0x41', 'VK_LEFT'\n"
        "ACTION : 1|'down'  to press,  0|'up' to release,  'tap' to press+delay+release (non-blocking)\n"
        "TAP_MS : tap duration (ms), default 50. Returns immediately.\n"
        "Notes  : No MEX API is used off-thread; stable with browsers and MATLAB focus changes.\n"
    );
}

static int is_string_scalar(const mxArray* a) { return mxIsChar(a) && mxGetM(a)*mxGetN(a) > 0; }
static char* to_cstring(const mxArray* a) { if (!mxIsChar(a)) return NULL; return mxArrayToString(a); }
static int parse_action(const char* s, int* out) {
    if (!s) return 0;
    if (_stricmp(s,"down")==0){*out=1;return 1;}
    if (_stricmp(s,"up")==0){*out=0;return 1;}
    if (_stricmp(s,"tap")==0){*out=2;return 1;}
    return 0;
}

// ---------- MEX entry ----------
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs == 0) { print_help(); return; }
    if (nrhs < 2) mexErrMsgIdAndTxt("simulate_keypress:args","Need KEY and ACTION.");

    if (!is_string_scalar(prhs[0])) mexErrMsgIdAndTxt("simulate_keypress:badKey","KEY must be a string.");
    char* keystr = to_cstring(prhs[0]); if (!keystr) mexErrMsgIdAndTxt("simulate_keypress:conv","KEY convert failed.");

    int action=-1;
    if (mxIsChar(prhs[1])) {
        char* act = to_cstring(prhs[1]); int ok = parse_action(act, &action); mxFree(act);
        if (!ok) { mxFree(keystr); mexErrMsgIdAndTxt("simulate_keypress:badAction","ACTION must be 'down','up','tap' or 1/0."); }
    } else if (mxIsDouble(prhs[1]) || mxIsSingle(prhs[1])) {
        double v=mxGetScalar(prhs[1]); if (v==1.0) action=1; else if (v==0.0) action=0;
        else { mxFree(keystr); mexErrMsgIdAndTxt("simulate_keypress:badAction","Numeric ACTION must be 1 or 0."); }
    } else { mxFree(keystr); mexErrMsgIdAndTxt("simulate_keypress:badActionType","ACTION must be string or numeric."); }

    DWORD tap_ms = 50;
    if (action==2 && nrhs>=3) {
        if (!(mxIsDouble(prhs[2])||mxIsSingle(prhs[2])) || mxIsComplex(prhs[2]) || mxGetNumberOfElements(prhs[2])<1) {
            mxFree(keystr); mexErrMsgIdAndTxt("simulate_keypress:badTapMs","TAP_MS must be numeric scalar.");
        }
        double ms=mxGetScalar(prhs[2]); if (ms<0) ms=0; tap_ms=(DWORD)(ms+0.5);
    }

    WORD vk=0, sc=0; int extended=0;
    if (!resolve_key(keystr,&vk,&sc,&extended) || sc==0) {
        mxFree(keystr);
        mexErrMsgIdAndTxt("simulate_keypress:unknownKey","Unrecognized KEY '%s'.", keystr);
    }
    mxFree(keystr);

    if (action==1 || action==0) {
        UINT sent = send_key_event(sc, extended, action==1);
        if (sent==0) {
            DWORD err=GetLastError();
            mexWarnMsgIdAndTxt("simulate_keypress:SendInputFailed","SendInput failed (GetLastError=%lu).",(unsigned long)err);
        }
        if (nlhs>0) plhs[0]=mxCreateDoubleScalar((double)sent);
        return;
    }

    // Non-blocking TAP: key down now, schedule key up via timer queue.
    ensure_timer_queue();

    // Key down immediately
    if (send_key_event(sc, extended, 1) == 0) {
        DWORD err=GetLastError();
        mexWarnMsgIdAndTxt("simulate_keypress:SendInputFailed","SendInput (down) failed (err=%lu).",(unsigned long)err);
    }

    // Allocate args and schedule one-shot timer for release
    UpArgs* a = (UpArgs*)malloc(sizeof(UpArgs));
    if (!a) mexErrMsgIdAndTxt("simulate_keypress:oom","Out of memory.");
    a->sc = sc; a->extended = extended;

    HANDLE hTimer = NULL;
    BOOL ok = CreateTimerQueueTimer(
        &hTimer,                // out handle (not used later)
        g_timer_queue,          // shared queue
        up_timer_cb,            // callback
        a,                      // context
        tap_ms,                 // due time (ms)
        0,                      // period (0 = one-shot)
        WT_EXECUTEDEFAULT
    );
    if (!ok) {
        free(a);
        mexErrMsgIdAndTxt("simulate_keypress:timer","CreateTimerQueueTimer failed (err=%lu).", GetLastError());
    }

    if (nlhs>0) plhs[0]=mxCreateDoubleScalar(1.0); // scheduled
}
