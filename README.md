# Assembly Project: PIC16F877-Microprocessor

## About

An assembly project created for PIC16F877. Program to either count up, from 0 to 250 (in a circular way), count down, or stop counting - depending on the input voltage.


## The Algorithm

The program starts by displaying the number "000" and "STOP" on the LCD screen while waiting for an input voltage. The algorithm receives an input voltage and converts it from analog to digital.
If the voltage is within the range of 0.5v to 1.5v, the algorithm starts to count up every full second while displaying the current number and "UP" on the LCD screen.
If the voltage is within the range of 1.8v to 2.3v, the algorithm starts to count down every full second while displaying the current number and "DOWN" on the LCD screen.
If the voltage is NOT within any of the above-mentioned ranges, the algorithm stops counting and displays "STOP" on the LCD screen.



