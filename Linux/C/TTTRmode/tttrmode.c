/************************************************************************

  PicoHarp 300    PHlib  TTTR Mode Demo in C

  Demo access to PicoHarp 300 Hardware via PHlib v 2.3.
  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Michael Wahl, PicoQuant GmbH, April 2009

  Note: This is a console application (i.e. run in terminal / cmd box)
  
  Note v2.x: This is now a multi-device library. All functions take a device 
  index. New functions for Open and Close.

  Tested with the following compilers:
  Windows:
  - MinGW 2.0.0-3 (free compiler for Win 32 bit)
  - MS Visual C++ 6.0 (Win 32 bit)
  - Borland C++ 5.3 (Win 32 bit)
  Linux: 
  - gcc 3.3 through 4.1

************************************************************************/

#ifndef _WIN32
#define Sleep(msec) usleep(msec*1000)
#else
#include <windows.h>
#include <dos.h>
#include <conio.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


#include "phdefin.h"
#include "phlib.h"
#include "errorcodes.h"

unsigned int buffer[TTREADMAX];


int main(int argc, char* argv[])
{
 int i;
 int dev[MAXDEVNUM]; 
 int found=0;
 FILE *fpout; 
 int ret;
 char LIB_Version[8];
 char HW_Model[16];
 char HW_Version[8];
 char HW_Serial[8];
 char Errorstring[40];
 int Mode=MODE_T2; //set T2 or T3 here, observe suitable Syncdivider and Range!
 int Range=0;   //you can change this (meaningless in T2 mode, important in T3 mode!)
 int Offset=0;  //normally no need to change this
 int Tacq=10000;        //you can change this, unit is millisec
 int SyncDivider = 1;  //you can change this, observe Mode! READ MANUAL!
 int CFDZeroCross0=10; //you can change this
 int CFDLevel0=50; //you can change this
 int CFDZeroCross1=10; //you can change this
 int CFDLevel1=150; //you can change this
 int blocksz = 32768; //up to TTREADMAX in steps of 512
 int Resolution; 
 int Countrate0;
 int Countrate1;
 int flags;
 int FiFoWasFull,CTCDone,Progress;


 printf("\nPicoHarp 300  PHLib  TTTR Mode Demo    M. Wahl, PicoQuant GmbH, 2009");
 printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
 PH_GetLibraryVersion(LIB_Version);
 printf("\nPHLIB version is %s",LIB_Version);
 if(strncmp(LIB_Version,LIB_VERSION,sizeof(LIB_VERSION))!=0)
         printf("\nWarning: The application was built for version %s.",LIB_VERSION);

 if((fpout=fopen("tttrmode.out","wb"))==NULL)
 {
         printf("\ncannot open output file\n"); 
         goto ex;
 }

 printf("\n\n");
 printf("Mode             : %ld\n",Mode);
 printf("Range No         : %ld\n",Range);
 printf("Offset           : %ld\n",Offset);
 printf("AcquisitionTime  : %ld\n",Tacq);
 printf("SyncDivider      : %ld\n",SyncDivider);
 printf("CFDZeroCross0    : %ld\n",CFDZeroCross0);
 printf("CFDLevel0        : %ld\n",CFDLevel0);
 printf("CFDZeroCross1    : %ld\n",CFDZeroCross1);
 printf("CFDLevel1        : %ld\n",CFDLevel1);


 printf("\nSearching for PicoHarp devices...");
 printf("\nDevidx     Status");


 for(i=0;i<MAXDEVNUM;i++)
 {
	ret = PH_OpenDevice(i, HW_Serial); 
	if(ret==0) //Grab any PicoHarp we can open
	{
		printf("\n  %1d        S/N %s", i, HW_Serial);
		dev[found]=i; //keep index to devices we want to use
		found++;
	}
	else
	{
		if(ret==ERROR_DEVICE_OPEN_FAIL)
			printf("\n  %1d        no device", i);
		else 
		{
			PH_GetErrorString(Errorstring, ret);
			printf("\n  %1d        %s", i,Errorstring);
		}
	}
 }

 //in this demo we will use the first PicoHarp device we found, i.e. dev[0]
 //you could also check for a specific serial number, so that you always know 
 //which physical device you are talking to.

 if(found<1)
 {
	printf("\nNo device available.");
	goto ex; 
 }
 printf("\nUsing device #%1d",dev[0]);
 printf("\nInitializing the device...");

 ret = PH_Initialize(dev[0],Mode); 
 if(ret<0)
 {
        printf("\nPH init error %d. Aborted.\n",ret);
        goto ex;
 }
 
 ret = PH_GetHardwareVersion(dev[0],HW_Model,HW_Version); /*this is only for information*/
 if(ret<0)
 {
        printf("\nPH_GetHardwareVersion error %d. Aborted.\n",ret);
        goto ex;
 }
 else
	printf("\nFound Model %s Version %s",HW_Model,HW_Version);

 printf("\nCalibrating...");
 ret=PH_Calibrate(dev[0]);
 if(ret<0)
 {
        printf("\nCalibration Error %d. Aborted.\n",ret);
        goto ex;
 } 
                
 ret = PH_SetSyncDiv(dev[0],SyncDivider);
 if(ret<0)
 {
        printf("\nPH_SetSyncDiv error %ld. Aborted.\n",ret);
        goto ex;
 }

 ret=PH_SetCFDLevel(dev[0],0,CFDLevel0);
 if(ret<0)
 {
        printf("\nPH_SetCFDLevel error %ld. Aborted.\n",ret);
        goto ex;
 }

 ret = PH_SetCFDZeroCross(dev[0],0,CFDZeroCross0);
 if(ret<0)
 {
        printf("\nPH_SetCFDZeroCross error %ld. Aborted.\n",ret);
        goto ex;
 }

 ret=PH_SetCFDLevel(dev[0],1,CFDLevel1);
 if(ret<0)
 {
        printf("\nPH_SetCFDLevel error %ld. Aborted.\n",ret);
        goto ex;
 }

 ret = PH_SetCFDZeroCross(dev[0],1,CFDZeroCross1);
 if(ret<0)
 {
        printf("\nPH_SetCFDZeroCross error %ld. Aborted.\n",ret);
        goto ex;
 }

 ret = PH_SetRange(dev[0],Range);
 if(ret<0)
 {
        printf("\nPH_SetRange error %d. Aborted.\n",ret);
        goto ex;
 }

 ret = PH_SetOffset(dev[0],Offset);
 if(ret<0)
 {
        printf("\nPH_SetOffset error %d. Aborted.\n",ret);
        goto ex;
 }


 Resolution = PH_GetResolution(dev[0]);

 //Note: after Init or SetSyncDiv you must allow 100 ms for valid new count rate readings
 Sleep(200); //linux fixme!
 Countrate0 = PH_GetCountRate(dev[0],0);
 Countrate1 = PH_GetCountRate(dev[0],1);

 printf("\nResolution=%1dps Countrate0=%1d/s Countrate1=%1d/s", Resolution, Countrate0, Countrate1);


 Progress = 0;
 printf("\nProgress:%9d",Progress);

 ret = PH_StartMeas(dev[0],Tacq);
 if(ret<0)
 {
        printf("\nError in StartMeas. Aborted.\n");
        goto ex;
 }

 while(1)  
 {
		flags=PH_GetFlags(dev[0]);
		if (flags<0) 
		{
			printf("\nGetFlags error %d\n",flags); 
			goto stoptttr;
		}

		FiFoWasFull=flags&FLAG_FIFOFULL;
   
		if (FiFoWasFull) 
		{
			printf("\nFiFo Overrun!\n"); 
			goto stoptttr;
		}
		
		ret = PH_TTReadData(dev[0],buffer,blocksz);	//may return less!  
		if(ret<0) 
		{ 
			printf("\nReadData error %d\n",ret); 
			goto stoptttr; 
		}  

		if(ret) 
		{
			if(fwrite(buffer,4,ret,fpout)!=(unsigned)ret)
			{
				printf("\nfile write error\n");
				goto stoptttr;
			}               
				Progress += ret;
				printf("\b\b\b\b\b\b\b\b\b%9d",Progress);
				fflush(stdout);
		}
		else
		{
			CTCDone=PH_CTCStatus(dev[0]);
			if (CTCDone<0) 
			{ 
				printf("\nPH_CTCStatus error %d\n",CTCDone); 
				goto stoptttr; 
			} 
			if (CTCDone) 
			{ 
				printf("\nDone\n"); 
				goto stoptttr; 
			}  
		}
		Countrate0 = PH_GetCountRate(dev[0],0); //can be called here if needed
		Countrate1 = PH_GetCountRate(dev[0],1); //can be called here if needed
 }

stoptttr:

 PH_StopMeas(dev[0]);

ex:

 for(i=0;i<MAXDEVNUM;i++) //no harm to close all
 {
	PH_CloseDevice(i);
 }

 if(fpout) fclose(fpout);
 printf("\npress RETURN to exit");
 getchar();
 return 0;
}
