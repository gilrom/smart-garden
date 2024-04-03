#ifndef DISPLAY_H
#define DISPLAY_H

unsigned long display_timout = 10000;
bool pixelCheck;
int tuning_on = 0;

void mainLoopDispaly (void* params);
void displayInit();

#endif