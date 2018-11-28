/********************MangoMIPS32*******************
Filename:   Config.v
Author:     RickyTino
Version:    v1.0.0
**************************************************/

//Note: The result is UNPREDICTABLE if values are set out of the range indicated.

/*------------------------------------------------
Define "No_Branch_Delay_Slot" to disable the execution of delay slot instruction 
when a branch or jump is taken.
P.S.: Under this circumstance, there's no difference between branch instructions
and branch likely instructions.
*/
//`define No_Branch_Delay_Slot
/*------------------------------------------------
Define “NSCSCC_Mode" to meet the requirement of NSCSCC-2018 functional tests.
Changes in configuration includes:
- Disabe Cause.IV (Ignore on write and read as zero)
*/
`define NSCSCC_Mode