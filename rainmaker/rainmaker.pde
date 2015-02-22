/**
 * Moneycounts
 * 
 * Controls:
 * WASD movement
 * Q/E spin left/right
 * R/F go up/down
 * Space to hover
 * Shift = takeoff
 * Ctrl = land
 **/

import com.shigeodayo.ardrone.processing.*;

// represents the drone in the ardrone library
ARDroneForP5 ardrone;

// used for lifecycle of getting votes and making actions from them
long timeOfLastUpdate;

// movement variables
final int MIN_SPEED = 1;
final int MAX_SPEED = 10;
final int ACCEL = 1;
int speed = MIN_SPEED; // constrained to ints [1, 100] in ardrone library

// action vairables
final int STAND_STILL = 0;
final int GO_FORWARD = 1;
final int GO_BACKWARD = 2;
final int GO_LEFT = 3;
final int GO_RIGHT = 4;
int action = STAND_STILL;

// operator override, true when keyboard has priority to votes
// unused
boolean operatorOverride = false; 

// not put in yet
boolean noDroneMode = false;

void setup() {
    size(640, 240); // left half = camera, right = our stuff
    
    if(!noDroneMode) {
      ardrone = new ARDroneForP5("192.168.1.1");
      ardrone.connect(); // connect to the AR.Drone
      ardrone.connectNav(); // for getting sensor information
      ardrone.connectVideo(); // for getting video information
      ardrone.start(); // start to control AR.Drone and get sensor and video data of it
      ardrone.setMaxAltitude(10);
    }
    
    // begin recording time for votes-update lifecycle
    timeOfLastUpdate = millis();
}

void drawDiagnostics() {
    // getting sensor information of AR.Drone
    float pitch = ardrone.getPitch();
    float roll = ardrone.getRoll();
    float yaw = ardrone.getYaw();
    float altitude = ardrone.getAltitude();
    float[] velocity = ardrone.getVelocity();
    int battery = ardrone.getBatteryPercentage();
  
    String attitude = "pitch:" + pitch + "\nroll:" + roll + "\nyaw:" + yaw + "\naltitude:" + altitude;
    text(attitude, 20, 85);
    String vel = "vx:" + velocity[0] + "\nvy:" + velocity[1];
    text(vel, 20, 140);
    String bat = "battery:" + battery + " %";
    text(bat, 20, 170);
}

void getVotesAndNextAction() {
    // get JSON vote data from API
    JSONArray siteJSON = loadJSONArray("https://sway-rainmaker.herokuapp.com/api/v1/votes");
    
    int lr = 0;
    int fb = 0;
    
    for(int i = 0; i < siteJSON.size(); i++) {
        JSONObject item = siteJSON.getJSONObject(i);
        
        String text = item.getString("description")
                          .substring(0, 1) // 1st char
                          .toLowerCase();
        
        if(text.equals("l")) lr--;
        if(text.equals("r")) lr++;
        if(text.equals("f")) fb++;
        if(text.equals("b")) fb--;
        
        fill(255);
        text(text, 330, 20 + 20 * i);
    }
    
    fill(255);
    text("total lr: " + lr, 350, 20);
    text("total fb: " + fb, 350, 40);
    
    // reset speed to MIN
    speed = MIN_SPEED;
    
    if(lr == 0 && fb == 0) { // sum=0? Hover in place 
        action = STAND_STILL; 
    } else if(abs(lr) > abs(fb)) { // left/right movement
        if(lr > 0) action = GO_RIGHT;
        if(lr < 0) action = GO_LEFT;
    } else { // in case of ties, move forward/back
        if(fb > 0) action = GO_FORWARD;
        if(fb < 0) action = GO_BACKWARD;
    }
    
    // println("ACTION: " + actionFromInt(action));
    
    timeOfLastUpdate = millis();
}

String actionFromInt(int actInt) {
    if     (actInt == 0) return "STAND-STILL";
    else if(actInt == 1) return "GO FORWARD";
    else if(actInt == 2) return "GO BACKWARD";
    else if(actInt == 3) return "GO LEFT";
    else if(actInt == 4) return "GO RIGHT";
    else                 return "WTF ACTION";
}

void draw() {
    background(204);
    
    // getting image from AR.Drone
    // true: resizeing image automatically
    // false: not resizing
    PImage img = ardrone.getVideoImage(false);
    if (img == null)
      return;
    image(img, 0, 0);
  
    // print out AR.Drone information
    // ardrone.printARDroneInfo();
    
    // draw drone info onto canvas
    drawDiagnostics();
    
    // determine cycle drone is in
    long timeSinceLastUpdate = millis() - timeOfLastUpdate;
    boolean beenTwoSeconds = timeSinceLastUpdate > 2000;
    boolean beenFourSeconds = timeSinceLastUpdate > 4000;
    boolean beenFiveSeconds = timeSinceLastUpdate > 5000;
    
    // decide action
    if(beenFiveSeconds) {
        getVotesAndNextAction();
    } else if(beenFourSeconds) { // stop after 4 seconds
        speed = MIN_SPEED;
        action = STAND_STILL;
    } else if(beenTwoSeconds) { // decelerate
        speed -= ACCEL;
    } else { // accelerate in action direction
        speed += ACCEL;
    }
    
    text("Sec: " + (timeSinceLastUpdate / (float) 1000), 350, 200);
    text("Act: " + actionFromInt(action), 350, 220);
    
    speed = constrain(speed, MIN_SPEED, MAX_SPEED);
    
    // perform action if nothing else is working
    if(!keyPressed) {
      if(action == GO_FORWARD)  ardrone.forward(speed);
      if(action == GO_BACKWARD) ardrone.backward(speed);
      if(action == GO_LEFT)     ardrone.spinLeft(speed);
      if(action == GO_RIGHT)    ardrone.spinRight(speed);
    }
}

// key input control- must hold!
void keyPressed() {
    if (key == CODED) {
        if (keyCode == SHIFT)   ardrone.takeOff(); // take off, AR.Drone cannot move while landing
        if (keyCode == CONTROL) { // land! 
          ardrone.landing(); 
          noLoop();
        }
    } 
    else {
        println("pressed: " + key);
      
        if (key == 'w') ardrone.forward(80); // go forward
        if (key == 'a') ardrone.goLeft(80); // go left
        if (key == 's') ardrone.backward(80); // go backward
        if (key == 'd') ardrone.goRight(80); // go right
        if (key == 'q') ardrone.spinLeft(80); // spin right
        if (key == 'e') ardrone.spinRight(80); // spin left
        if (key == 'r') ardrone.up(100); // go up
        if (key == 'f') ardrone.down(100); // go down
        if (key == ' ') ardrone.stop(); // hovering
        
        /*
        else if (key == '1') ardrone.setHorizontalCamera(); // set front camera
        else if (key == '2') ardrone.setHorizontalCameraWithVertical(); // set front camera with second camera (upper left)
        else if (key == '3') ardrone.setVerticalCamera(); // set second camera
        else if (key == '4') ardrone.setVerticalCameraWithHorizontal(); //set second camera with front camera (upper left)
        else if (key == '5') ardrone.toggleCamera(); // set next camera setting
        */
    }
}

void keyReleased() {
    ardrone.stop();
}

