//MEGA_RIPPLE_TMSI_INTERFACE  Makes an interface between RIPPLE stim system and TMSi acquisition.
//
// Serial commands:
// -> 'reset' : Reset the counter for the current experiment
// -> 'notify:<message>' : Send message to the other system
//    e.g. 'notify:blablabla'
// -> 'key:<value>' : Sets a new key (for example if you reset to 0 on accident)
//    e.g. 'key:221'
// -> 'n:<value>' : Sets a new total number of pulses per experiment
//    e.g. 'n:1000'

//Load Libraries:
#include <LiquidCrystal_PCF8574.h>

#define STIM_INDICATOR_IN 48
#define RECORD_INDICATOR_IN 50
#define LED_DEBUG_STIM_OUT 49
#define LED_DEBUG_REC_OUT 51

long n_stims, n_trials, params_key;
bool stim_ongoing, recording_ongoing, permit_stims;
String inString, tmp;
LiquidCrystal_PCF8574 lcd(0x3F); // set the LCD address to 0x27 (common)

void setup() {
  stim_ongoing = false;
  recording_ongoing = false;
  permit_stims = false;
  inString = "";
  n_trials = 20;
  params_key = 0;
  n_stims = 0;
  tmp.reserve(64);
  inString.reserve(256);
  
  // put your setup code here, to run once:
  pinMode(LED_DEBUG_STIM_OUT, OUTPUT);
  digitalWrite(LED_DEBUG_STIM_OUT, LOW);
  pinMode(LED_DEBUG_REC_OUT, OUTPUT);
  digitalWrite(LED_DEBUG_REC_OUT, LOW);
  pinMode(STIM_INDICATOR_IN, INPUT);
  pinMode(RECORD_INDICATOR_IN, INPUT);

  Serial.begin(115200);
  Serial1.begin(115200);

  while (!Serial) {
    ; // wait for Serial connection to TMSi controller computer
  }
  while (!Serial1) {
    ; // wait for Serial connection to Ripple controller computer
  }
  _init();
}

void _init() {
  Serial.println("TMSi");
  Serial1.println("Ripple");
  reset_lcd("[INIT]", "experiment reset");
  Serial.flush();
  Serial1.flush();
}

void loop() {
  if (Serial.available() > 0) {
    // read the incoming string:
    inString = Serial.readString();
    inString.trim();
    _parse_serial_string();
  }
  
  if (Serial1.available() > 0) {
    // read the incoming string:
    inString = Serial1.readString();
    inString.trim();
    _parse_serial_string();
  }
  
  // put your main code here, to run repeatedly:
  if (digitalRead(STIM_INDICATOR_IN)==HIGH) {
    _handle_stim_ttl_indicator_high();
  } else {
    _handle_stim_ttl_indicator_low();
  }

  if (digitalRead(RECORD_INDICATOR_IN)==HIGH) {
    _handle_record_ttl_indicator_high();
  } else {
    _handle_record_ttl_indicator_low();
  }
}

// BEGIN: LCD FUNCTIONS
void reset_lcd(String msg1, String msg2) {
  n_stims = 0;
  lcd.begin(16, 2);
  lcd.noBlink();
  lcd.noCursor();
  lcd.setBacklight(0);
  delay(400);
  lcd.setBacklight(255);
  lcd.home();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(msg1);
  lcd.setCursor(0, 1);
  lcd.print(msg2);
  delay(1000);
  lcd.setBacklight(128);
  delay(400);
  _update_lcd();
  return;
}

void _update_lcd() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Key: " + String(params_key));
  lcd.setCursor(0, 1);
  lcd.print(String(n_stims) + " / " + String(n_trials));
  return;
}

// END: LCD FUNCTIONS

// BEGIN: HANDLE TTL INPUTS
void _handle_stim_ttl_indicator_high() {
  if (!stim_ongoing && permit_stims && recording_ongoing) {
      Serial.println("stim");
      Serial1.println("stim");
      digitalWrite(LED_DEBUG_STIM_OUT, HIGH);
      stim_ongoing = true;
      n_stims = n_stims + 1;
      _update_lcd(); 
    }
}

void _handle_stim_ttl_indicator_low() {
  if (stim_ongoing) {
    digitalWrite(LED_DEBUG_STIM_OUT, LOW);
    stim_ongoing = false;
  }
}

void _handle_record_ttl_indicator_high() {
  if (!recording_ongoing) {
    if (permit_stims) {
      Serial.println("resume");
      Serial1.println("resume");
    } else {
      Serial.println("start");
      Serial1.println("start");
    }
    digitalWrite(LED_DEBUG_REC_OUT, HIGH);
    recording_ongoing = true; 
    permit_stims = true;
    _update_lcd();
  } else {
    if (n_stims == n_trials) {
      digitalWrite(LED_DEBUG_REC_OUT, LOW);
      permit_stims = false;
    }
  }
}

void _handle_record_ttl_indicator_low() {
  if (recording_ongoing) {
      if (permit_stims) {
        Serial.println("pause"); 
        Serial1.println("pause");
      }
      recording_ongoing = false;
      digitalWrite(LED_DEBUG_REC_OUT, LOW);
      if (n_stims >= n_trials) {
        params_key = params_key + 1;
        n_stims = 0;
        Serial.println("stop");
        Serial1.println("stop");
        _update_lcd();
      } 
    }
}
// END: HANDLE TTL INPUTS

// BEGIN: STRING PARSING FUNCTIONS

void _parse_serial_string() {
  if (inString.substring(0, 5) == "reset") {
      n_stims = 0;
      recording_ongoing = false;
      permit_stims = false;
      Serial.println("reset");
      Serial1.println("reset");
      _update_lcd();
      return;
    } else if (inString.substring(0, 4) == "init") {
      _init();
    } else if (inString.substring(0, 2) == "rs") {
      Serial1.println("rs");
      Serial.println("rs");
    } else if (inString.substring(0, 2) == "rp") {
      Serial1.println("rp");
      Serial.println("rp");
    } else if (inString.substring(0, 7) == "notify:") {
      Serial.println(inString.substring(7));
      Serial1.println(inString.substring(7));
      return;
    } else if (inString.substring(0, 11) == "stimconfig:") {
      Serial.println(inString);
      Serial1.println(inString);
      inString = inString.substring(11);
      params_key = _parse_params_key(inString);
      n_stims = _parse_n_stims(inString);
      n_trials = _parse_n_trials(inString);
      _update_lcd();
      return;
    } else {
      Serial.println("Unknown command: " + inString);
      Serial1.println("Unknown command: " + inString);
      return;
    }
}

long _parse_params_key(String s) {
  // get params_key (Key=<value>;)
  int firstIndex = s.indexOf("Key=") + 4; // 4 characters in "Key="
  int lastIndex = s.indexOf(';', firstIndex); // up to ';' after "Key="
  tmp = s.substring(firstIndex, lastIndex);
  return tmp.toInt();
}

long _parse_n_stims(String s) {
    // get n_stims (Progress=<value>;)
  int firstIndex = s.indexOf("Progress=") + 9; // 9 characters in "Progress="
  int lastIndex = s.indexOf(';', firstIndex); // up to ';' after "Progress="
  tmp = s.substring(firstIndex, lastIndex);
  return  tmp.toInt();
}

long _parse_n_trials(String s) {
  // get n_trials (NumberTrials=<value>;)
  int firstIndex = s.indexOf("NumberTrials=") + 13; // 13 characters in "NumberTrials="
  int lastIndex = s.indexOf(';', firstIndex); // up to ';' after "NumberTrials="
  tmp = s.substring(firstIndex, lastIndex);
  return tmp.toInt();  
}

// END: STRING PARSING FUNCTIONS
