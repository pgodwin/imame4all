/*
 * This file is part of iMAME4all.
 *
 * Copyright (C) 2010 David Valdeita (Seleuco)
 *
 * based on:
 *
 *  wiiuse
 *
 *	Written By:
 *		Michael Laforest	< para >
 *		Email: < thepara (--AT--) g m a i l [--DOT--] com >
 *
 *	Copyright 2006-2007
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * In addition, as a special exception, Seleuco
 * gives permission to link the code of this program with
 * the MAME library (or with modified versions of MAME that use the
 * same license as MAME), and distribute linked combinations including
 * the two.  You must obey the GNU General Public License in all
 * respects for all of the code used other than MAME.  If you modify
 * this file, you may extend this exception to your version of the
 * file, but you are not obligated to do so.  If you do not wish to
 * do so, delete this exception statement from your version.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#import <btstack/btstack.h>
#include "wiimote.h"
#include "minimal.h"

int num_of_joys = 0;
struct wiimote_t joys[4];
extern int iOS_exitGame;
extern int iOS_wiiDeadZoneValue;
extern int iOS_inGame;
extern int iOS_waysStick;
#define STICK4WAY (iOS_waysStick == 4 && iOS_inGame)
#define STICK2WAY (iOS_waysStick == 2 && iOS_inGame)

int wiimote_send(struct wiimote_t* wm, byte report_type, byte* msg, int len);
int wiimote_read_data(struct wiimote_t* wm, unsigned int addr, unsigned short len);
int wiimote_write_data(struct wiimote_t* wm, unsigned int addr, byte* data, byte len);
void wiimote_set_leds(struct wiimote_t* wm, int leds);
int classic_ctrl_handshake(struct wiimote_t* wm, struct classic_ctrl_t* cc, byte* data, unsigned short len);
void classic_ctrl_event(struct classic_ctrl_t* cc, byte* msg);

int wiimote_remove(uint16_t source_cid, bd_addr_t *addr){

    int i = 0;
    int unid = -1;
    int found = 0;
    for(;i<num_of_joys;i++)
    {
       if(joys[i].c_source_cid==source_cid && !found)
       {
          found=1;
           struct wiimote_t *wm = NULL;
           wm = &joys[i];
           if(WIIMOTE_DBG)printf("%02x:%02x:%02x:%02x:%02x:%02x\n",wm->addr[0], wm->addr[1], wm->addr[2],wm->addr[3], wm->addr[4], wm->addr[5]);
           memcpy(addr,&(wm->addr),BD_ADDR_LEN);
           unid = wm->unid;
          continue;
       }
       if(found)
       {
          memcpy(&joys[i-1],&joys[i],sizeof(struct wiimote_t ));
          joys[i-1].unid = i-1;
          struct wiimote_t *wm = NULL;
          wm = &joys[i-1];
		  if(wm->unid==0)
			  wiimote_set_leds(wm, WIIMOTE_LED_1);
		  else if(wm->unid==1)
			  wiimote_set_leds(wm, WIIMOTE_LED_2);
		  else if(wm->unid==2)
			  wiimote_set_leds(wm, WIIMOTE_LED_3);
		  else if(wm->unid==3)
			  wiimote_set_leds(wm, WIIMOTE_LED_4);
       }
    }
    if(found)
    {
      num_of_joys--;
      if(WIIMOTE_DBG)printf("NUM JOYS %d\n",num_of_joys);
      return unid;
    }
    return unid;
}

/**
 *	@brief Find a wiimote_t structure by its source_cid.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *	@param wiimotes	The number of wiimote_t structures in \a wm.
 *	@param unid		The unique identifier to search for.
 *
 *	@return Pointer to a wiimote_t structure, or NULL if not found.
 */

struct wiimote_t* wiimote_get_by_source_cid(uint16_t source_cid){

	int i = 0;

	for (; i < num_of_joys; ++i) {
		if(WIIMOTE_DBG)printf("0x%02x 0x%02x\n",joys[i].i_source_cid,source_cid);
		if (joys[i].i_source_cid == source_cid)
			return &joys[i];
	}

	return NULL;
}

/**
 *	@brief Request the wiimote controller status.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *
 *	Controller status includes: battery level, LED status, expansions
 */
void wiimote_status(struct wiimote_t* wm) {
	byte buf = 0;

	if (!wm || !WIIMOTE_IS_CONNECTED(wm))
		return;

	if(WIIMOTE_DBG)printf("Requested wiimote status.\n");

	wiimote_send(wm, WM_CMD_CTRL_STATUS, &buf, 1);
}

void wiimote_data_report(struct wiimote_t* wm, byte type) {
	byte buf[2] = {0x0,0x0};

	if (!wm  || !WIIMOTE_IS_CONNECTED(wm))
		return;

    buf[1] = type;
//CUIDADO es un &buf?
	wiimote_send(wm, WM_CMD_REPORT_TYPE, buf, 2);
}


/**
 *	@brief	Set the enabled LEDs.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *	@param leds		What LEDs to enable.
 *
 *	\a leds is a bitwise or of WIIMOTE_LED_1, WIIMOTE_LED_2, WIIMOTE_LED_3, or WIIMOTE_LED_4.
 */
void wiimote_set_leds(struct wiimote_t* wm, int leds) {
	byte buf;

	if (!wm || !WIIMOTE_IS_CONNECTED(wm))
		return;

	/* remove the lower 4 bits because they control rumble */
	wm->leds = (leds & 0xF0);

	buf = wm->leds;

	wiimote_send(wm, WM_CMD_LED, &buf, 1);
}

/**
 *	@brief Find what buttons are pressed.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *	@param msg		The message specified in the event packet.
 */
void wiimote_pressed_buttons(struct wiimote_t* wm, byte* msg) {
	short now;

	/* convert to big endian */
	now = BIG_ENDIAN_SHORT(*(short*)msg) & WIIMOTE_BUTTON_ALL;

	/* buttons pressed now */
	wm->btns = now;
}

/**
 *	@brief Handle data from the expansion.
 *
 *	@param wm		A pointer to a wiimote_t structure.
 *	@param msg		The message specified in the event packet for the expansion.
 */
void wiimote_handle_expansion(struct wiimote_t* wm, byte* msg) {
	switch (wm->exp.type) {
		case EXP_CLASSIC:
			classic_ctrl_event(&wm->exp.classic, msg);
			break;
		default:
			break;
	}
}

/**
*	@brief Get initialization data from the wiimote.
*
*	@param wm		Pointer to a wiimote_t structure.
*	@param data		unused
*	@param len		unused
*
*	When first called for a wiimote_t structure, a request
*	is sent to the wiimote for initialization information.
*	This includes factory set accelerometer data.
*	The handshake will be concluded when the wiimote responds
*	with this data.
*/
int wiimote_handshake(struct wiimote_t* wm,  byte event, byte* data, unsigned short len) {

	if (!wm) return 0;

	while(1)
	{
		if(WIIMOTE_DBG)printf("Handshake %d\n",wm->handshake_state);
		switch (wm->handshake_state) {
		   case 0://no ha habido nunca handshake, debemos forzar un mensaje de staus para ver que pasa.
		   {
				WIIMOTE_ENABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE);
				wiimote_set_leds(wm, WIIMOTE_LED_NONE);

				/* request the status of the wiimote to see if there is an expansion */
				wiimote_status(wm);

				wm->handshake_state=1;
				return 0;
			}
			case 1://estamos haciendo handshake o bien se necesita iniciar un nuevo handshake ya que se inserta(quita una expansion.
			{
				 int attachment = 0;

				 if(event != WM_RPT_CTRL_STATUS)
				   return 0;

				/* is an attachment connected to the expansion port? */
				 if ((data[2] & WM_CTRL_STATUS_BYTE1_ATTACHMENT) == WM_CTRL_STATUS_BYTE1_ATTACHMENT)
				 {
					attachment = 1;
				 }

				 if(WIIMOTE_DBG)printf("attachment %d %d\n",attachment,WIIMOTE_IS_SET(wm, WIIMOTE_STATE_EXP));

				/* expansion port */
				if (attachment && !WIIMOTE_IS_SET(wm, WIIMOTE_STATE_EXP)) {
					WIIMOTE_ENABLE_STATE(wm, WIIMOTE_STATE_EXP);

				    /* send the initialization code for the attachment */
					if(WIIMOTE_DBG)printf("haciendo el handshake de la expansion\n");

					if(WIIMOTE_IS_SET(wm,WIIMOTE_STATE_HANDSHAKE_COMPLETE))
					{
						if(WIIMOTE_DBG)printf("rehandshake\n");
						WIIMOTE_DISABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE_COMPLETE);
						WIIMOTE_ENABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE);//forzamos un handshake por si venimos de un hanshake completo
					}

					byte buf;
					//Old way. initialize the extension was by writing the single encryption byte 0x00 to 0x(4)A40040
					//buf = 0x00;
					//wiimote_write_data(wm, WM_EXP_MEM_ENABLE, &buf, 1);

					//NEW WAY 0x55 to 0x(4)A400F0, then writing 0x00 to 0x(4)A400FB. (support clones)
					buf = 0x55;
					wiimote_write_data(wm, 0x04A400F0, &buf, 1);
					usleep(100000);
					buf = 0x00;
					wiimote_write_data(wm, 0x04A400FB, &buf, 1);

					//check extension type!
					usleep(100000);
					wiimote_read_data(wm, WM_EXP_MEM_CALIBR+220, 4);
					//wiimote_read_data(wm, WM_EXP_MEM_CALIBR, EXP_HANDSHAKE_LEN);

					wm->handshake_state = 4;
					return 0;

			    } else if (!attachment && WIIMOTE_IS_SET(wm, WIIMOTE_STATE_EXP)) {
				    /* attachment removed */
					WIIMOTE_DISABLE_STATE(wm, WIIMOTE_STATE_EXP);
				    wm->exp.type = EXP_NONE;

					if(WIIMOTE_IS_SET(wm,WIIMOTE_STATE_HANDSHAKE_COMPLETE))
					{
						if(WIIMOTE_DBG)printf("rehandshake\n");
						WIIMOTE_DISABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE_COMPLETE);
						WIIMOTE_ENABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE);//forzamos un handshake por si venimos de un hanshake completo
					}
				}

				if(!attachment &&  WIIMOTE_IS_SET(wm,WIIMOTE_STATE_HANDSHAKE))
				{
					wm->handshake_state = 2;
					continue;
				}

				return 0;
			}
			case 2://find handshake no expansion
			{
				if(WIIMOTE_DBG)printf("Finalizado HANDSHAKE SIN EXPANSION\n");
				wiimote_data_report(wm,WM_RPT_BTN);
				wm->handshake_state = 6;
				continue;
			}
			case 3://find handshake expansion
			{
				if(WIIMOTE_DBG)printf("Finalizado HANDSHAKE CON EXPANSION\n");
				wiimote_data_report(wm,WM_RPT_BTN_EXP);
				wm->handshake_state = 6;
				continue;
			}
			case 4:
			{
				if(event !=  WM_RPT_READ)
				   return 0;

				int id = BIG_ENDIAN_LONG(*(int*)(data));

				if(WIIMOTE_DBG)printf("Expansion id=0x%04x\n",id);

				if(id!=/*EXP_ID_CODE_CLASSIC_CONTROLLER*/0xa4200101)
				{
					wm->handshake_state = 2;
					//WIIMOTE_DISABLE_STATE(wm, WIIMOTE_STATE_EXP);
					continue;
				}
				else
				{
					usleep(100000);
					wiimote_read_data(wm, WM_EXP_MEM_CALIBR, 16);//pedimos datos de calibracion del JOY!
					wm->handshake_state = 5;
				}

				return 0;
			}
			case 5:
			{
				if(event !=  WM_RPT_READ)
				   return 0;

				classic_ctrl_handshake(wm, &wm->exp.classic, data,len);
				wm->handshake_state = 3;
				continue;

			}
			case 6:
			{
				WIIMOTE_DISABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE);
				WIIMOTE_ENABLE_STATE(wm, WIIMOTE_STATE_HANDSHAKE_COMPLETE);
				wm->handshake_state = 1;
				if(wm->unid==0)
				  wiimote_set_leds(wm, WIIMOTE_LED_1);
				else if(wm->unid==1)
				  wiimote_set_leds(wm, WIIMOTE_LED_2);
				else if(wm->unid==2)
				  wiimote_set_leds(wm, WIIMOTE_LED_3);
				else if(wm->unid==3)
				  wiimote_set_leds(wm, WIIMOTE_LED_4);
				return 1;
			}
			default:
			{
				break;
			}
	    }
	}
}


/**
 *	@brief	Send a packet to the wiimote.
 *
 *	@param wm			Pointer to a wiimote_t structure.
 *	@param report_type	The report type to send (WIIMOTE_CMD_LED, WIIMOTE_CMD_RUMBLE, etc). Found in wiimote.h
 *	@param msg			The payload.
 *	@param len			Length of the payload in bytes.
 *
 *	This function should replace any write()s directly to the wiimote device.
 */
int wiimote_send(struct wiimote_t* wm, byte report_type, byte* msg, int len) {
	byte buf[32];

    buf[0] = WM_SET_REPORT | WM_BT_OUTPUT;
	buf[1] = report_type;

	memcpy(buf+2, msg, len);

	if(WIIMOTE_DBG)
	{
		int x = 2;
		printf("[DEBUG] (id %i) SEND: (%x) %.2x ", wm->unid, buf[0], buf[1]);
		for (; x < len+2; ++x)
			printf("%.2x ", buf[x]);
		printf("\n");
	}

	bt_send_l2cap( wm->c_source_cid, buf, len+2);
	return 1;
}

/**
 *	@brief	Read data from the wiimote (event version).
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *	@param addr		The address of wiimote memory to read from.
 *	@param len		The length of the block to be read.
 *
 *	The library can only handle one data read request at a time
 *	because it must keep track of the buffer and other
 *	events that are specific to that request.  So if a request
 *	has already been made, subsequent requests will be added
 *	to a pending list and be sent out when the previous
 *	finishes.
 */
int wiimote_read_data(struct wiimote_t* wm, unsigned int addr, unsigned short len) {
	//No puden ser mas de 16 lo leido o vendra en trozos!

	if (!wm || !WIIMOTE_IS_CONNECTED(wm))
		return 0;
	if (!len /*|| len > 16*/)
		return 0;

	byte buf[6];

	/* the offset is in big endian */
	*(int*)(buf) = BIG_ENDIAN_LONG(addr);

	/* the length is in big endian */
	*(short*)(buf + 4) = BIG_ENDIAN_SHORT(len);

	if(WIIMOTE_DBG)printf("Request read at address: 0x%x  length: %i", addr, len);
	wiimote_send(wm, WM_CMD_READ_DATA, buf, 6);

	return 1;
}

/**
 *	@brief	Write data to the wiimote.
 *
 *	@param wm			Pointer to a wiimote_t structure.
 *	@param addr			The address to write to.
 *	@param data			The data to be written to the memory location.
 *	@param len			The length of the block to be written.
 */
int wiimote_write_data(struct wiimote_t* wm, unsigned int addr, byte* data, byte len) {
	byte buf[21] = {0};		/* the payload is always 23 */

	if (!wm || !WIIMOTE_IS_CONNECTED(wm))
		return 0;
	if (!data || !len)
		return 0;

	if(WIIMOTE_DBG)printf("Writing %i bytes to memory location 0x%x...\n", len, addr);

	if(WIIMOTE_DBG)
	{
		int i = 0;
		printf("Write data is: ");
		for (; i < len; ++i)
			printf("%x ", data[i]);
		printf("\n");
	}

	/* the offset is in big endian */
	*(int*)(buf) = BIG_ENDIAN_LONG(addr);

	/* length */
	*(byte*)(buf + 4) = len;

	/* data */
	memcpy(buf + 5, data, len);

	wiimote_send(wm, WM_CMD_WRITE_DATA, buf, 21);
	return 1;
}


/////////////////////// CLASSIC  /////////////////

static void classic_ctrl_pressed_buttons(struct classic_ctrl_t* cc, short now);
void calc_joystick_state(struct joystick_t* js, float x, float y);

/**
 *	@brief Handle the handshake data from the classic controller.
 *
 *	@param cc		A pointer to a classic_ctrl_t structure.
 *	@param data		The data read in from the device.
 *	@param len		The length of the data block, in bytes.
 *
 *	@return	Returns 1 if handshake was successful, 0 if not.
 */
int classic_ctrl_handshake(struct wiimote_t* wm, struct classic_ctrl_t* cc, byte* data, unsigned short len) {
	int i;
	int offset = 0;

	cc->btns = 0;
	cc->r_shoulder = 0;
	cc->l_shoulder = 0;

	/* decrypt data */
	/*
	for (i = 0; i < len; ++i)
		data[i] = (data[i] ^ 0x17) + 0x17;
	*/

	if(WIIMOTE_DBG)
	{
		int x = 0;
		printf("[DECRIPTED]");
		for (; x < len; x++)
			printf("%.2x ", data[x]);
		printf("\n");
	}

/*
	if (data[offset] == 0xFF)
	{
		return 0;//ERROR!
	}
*/
	/* joystick stuff */
	if (data[offset] != 0xFF && data[offset] != 0x00)
	{
		cc->ljs.max.x = data[0 + offset] / 4;
		cc->ljs.min.x = data[1 + offset] / 4;
		cc->ljs.center.x = data[2 + offset] / 4;
		cc->ljs.max.y = data[3 + offset] / 4;
		cc->ljs.min.y = data[4 + offset] / 4;
		cc->ljs.center.y = data[5 + offset] / 4;

		cc->rjs.max.x = data[6 + offset] / 8;
		cc->rjs.min.x = data[7 + offset] / 8;
		cc->rjs.center.x = data[8 + offset] / 8;
		cc->rjs.max.y = data[9 + offset] / 8;
		cc->rjs.min.y = data[10 + offset] / 8;
		cc->rjs.center.y = data[11 + offset] / 8;
	}
	else
	{
		cc->ljs.max.x = 55;
		cc->ljs.min.x = 5;
		cc->ljs.center.x = 30;
		cc->ljs.max.y = 55;
		cc->ljs.min.y = 5;
		cc->ljs.center.y = 30;

		cc->rjs.max.x = 30;
		cc->rjs.min.x = 0;
		cc->rjs.center.x = 15;
		cc->rjs.max.y = 30;
		cc->rjs.min.y = 0;
		cc->rjs.center.y = 15;
	}

	/* handshake done */
	wm->exp.type = EXP_CLASSIC;

	return 1;
}

/**
 *	@brief Handle classic controller event.
 *
 *	@param cc		A pointer to a classic_ctrl_t structure.
 *	@param msg		The message specified in the event packet.
 */
void classic_ctrl_event(struct classic_ctrl_t* cc, byte* msg) {
	int i, lx, ly, rx, ry;
	byte l, r;

	/* decrypt data */
	/*
	for (i = 0; i < 6; ++i)
		msg[i] = (msg[i] ^ 0x17) + 0x17;
    */

	classic_ctrl_pressed_buttons(cc, BIG_ENDIAN_SHORT(*(short*)(msg + 4)));

	/* left/right buttons */
	l = (((msg[2] & 0x60) >> 2) | ((msg[3] & 0xE0) >> 5));
	r = (msg[3] & 0x1F);

	/*
	 *	TODO - LR range hardcoded from 0x00 to 0x1F.
	 *	This is probably in the calibration somewhere.
	 */
	cc->r_shoulder = ((float)r / 0x1F);
	cc->l_shoulder = ((float)l / 0x1F);

	/* calculate joystick orientation */
	lx = (msg[0] & 0x3F);
	ly = (msg[1] & 0x3F);
	rx = ((msg[0] & 0xC0) >> 3) | ((msg[1] & 0xC0) >> 5) | ((msg[2] & 0x80) >> 7);
	ry = (msg[2] & 0x1F);

	if(WIIMOTE_DBG)
		printf("%d %d %d %d\n",lx,ly,rx,ry);

	calc_joystick_state(&cc->ljs, lx, ly);
	calc_joystick_state(&cc->rjs, rx, ry);

	/*
	printf("classic L button pressed:         %f\n", cc->l_shoulder);
	printf("classic R button pressed:         %f\n", cc->r_shoulder);
	printf("classic left joystick angle:      %f\n", cc->ljs.ang);
	printf("classic left joystick magnitude:  %f\n", cc->ljs.mag);
	printf("classic right joystick angle:     %f\n", cc->rjs.ang);
	printf("classic right joystick magnitude: %f\n", cc->rjs.mag);
	*/
}


/**
 *	@brief Find what buttons are pressed.
 *
 *	@param cc		A pointer to a classic_ctrl_t structure.
 *	@param msg		The message byte specified in the event packet.
 */
static void classic_ctrl_pressed_buttons(struct classic_ctrl_t* cc, short now) {
	/* message is inverted (0 is active, 1 is inactive) */
	now = ~now & CLASSIC_CTRL_BUTTON_ALL;

	/* buttons pressed now */
	cc->btns = now;
}

/**
 *	@brief Calculate the angle and magnitude of a joystick.
 *
 *	@param js	[out] Pointer to a joystick_t structure.
 *	@param x	The raw x-axis value.
 *	@param y	The raw y-axis value.
 */
void calc_joystick_state(struct joystick_t* js, float x, float y) {
	float rx, ry, ang;

	/*
	 *	Since the joystick center may not be exactly:
	 *		(min + max) / 2
	 *	Then the range from the min to the center and the center to the max
	 *	may be different.
	 *	Because of this, depending on if the current x or y value is greater
	 *	or less than the assoicated axis center value, it needs to be interpolated
	 *	between the center and the minimum or maxmimum rather than between
	 *	the minimum and maximum.
	 *
	 *	So we have something like this:
	 *		(x min) [-1] ---------*------ [0] (x center) [0] -------- [1] (x max)
	 *	Where the * is the current x value.
	 *	The range is therefore -1 to 1, 0 being the exact center rather than
	 *	the middle of min and max.
	 */
	if (x == js->center.x)
		rx = 0;
	else if (x >= js->center.x)
		rx = ((float)(x - js->center.x) / (float)(js->max.x - js->center.x));
	else
		rx = ((float)(x - js->min.x) / (float)(js->center.x - js->min.x)) - 1.0f;

	if (y == js->center.y)
		ry = 0;
	else if (y >= js->center.y)
		ry = ((float)(y - js->center.y) / (float)(js->max.y - js->center.y));
	else
		ry = ((float)(y - js->min.y) / (float)(js->center.y - js->min.y)) - 1.0f;

	/* calculate the joystick angle and magnitude */
	ang = RAD_TO_DEGREE(atanf(ry / rx));
	ang -= 90.0f;
	if (rx < 0.0f)
		ang -= 180.0f;
	js->ang = absf(ang);
	js->mag = (float) sqrt((rx * rx) + (ry * ry));
	js->rx = rx;
	js->ry = ry;

}

////////////////////////////////////////////////////////////

extern float joy_analog_x[4];
extern float joy_analog_y[4];

int iOS_wiimote_check (struct  wiimote_t  *wm){
	 //printf("check %d\n",wm->unid);
	 joy_analog_x[wm->unid]=0.0f;
	 joy_analog_y[wm->unid]=0.0f;
	 int joyExKey = 0;
	 iOS_exitGame = 0;
	 if (1) {

			if (IS_PRESSED(wm, WIIMOTE_BUTTON_A))		{joyExKey |= GP2X_A;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_B))		{joyExKey |= GP2X_Y;}

			if (IS_PRESSED(wm, WIIMOTE_BUTTON_UP))		{joyExKey |= GP2X_LEFT;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN))	{joyExKey |= GP2X_RIGHT;}

			if (IS_PRESSED(wm, WIIMOTE_BUTTON_LEFT))	{
				if(!STICK2WAY &&
						!(STICK4WAY && (IS_PRESSED(wm, WIIMOTE_BUTTON_UP) ||
								       (IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN)))))
				joyExKey |= GP2X_DOWN;
			}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_RIGHT))	{
				if(!STICK2WAY &&
						!(STICK4WAY && (IS_PRESSED(wm, WIIMOTE_BUTTON_UP) ||
								       (IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN)))))
				joyExKey |= GP2X_UP;
			}

			if (IS_PRESSED(wm, WIIMOTE_BUTTON_MINUS))	{joyExKey |= GP2X_SELECT;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_PLUS))	{joyExKey |= GP2X_START;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_ONE))		{joyExKey |= GP2X_X;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_TWO))		{joyExKey |= GP2X_B;}
			if (IS_PRESSED(wm, WIIMOTE_BUTTON_HOME))	{

	          //usleep(50000);
	          iOS_exitGame = 1;}

			 if (wm->exp.type == EXP_CLASSIC) {

				    float deadZone;

				    switch(iOS_wiiDeadZoneValue)
				    {
				      case 0: deadZone = 0.12f;break;
				      case 1: deadZone = 0.15f;break;
				      case 2: deadZone = 0.17f;break;
				      case 3: deadZone = 0.2f;break;
				      case 4: deadZone = 0.3f;break;
				      case 5: deadZone = 0.4f;break;
				    }

				    //printf("deadzone %f\n",deadZone);

					struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;

					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZL))			joyExKey |= GP2X_R;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_B))			joyExKey |= GP2X_X;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_Y))			joyExKey |= GP2X_A;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_A))			joyExKey |= GP2X_B;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_X))			joyExKey |= GP2X_Y;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZR))			joyExKey |= GP2X_L;


					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_UP)){
						if(!STICK2WAY &&
								!(STICK4WAY && (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT) ||
										       (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT)))))
						  joyExKey |= GP2X_UP;
					}
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_DOWN)){
						if(!STICK2WAY &&
								!(STICK4WAY && (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT) ||
										       (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT)))))
						joyExKey |= GP2X_DOWN;
			        }
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT))		joyExKey |= GP2X_LEFT;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT))		joyExKey |= GP2X_RIGHT;


					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_L))		joyExKey |= GP2X_L;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_MINUS))		joyExKey |= GP2X_SELECT;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_HOME))		{//iOS_exitGame = 0;usleep(50000);
					                                                     iOS_exitGame = 1;}
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_PLUS))		joyExKey |= GP2X_START;
					if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_R))		joyExKey |= GP2X_R;

					if(cc->ljs.mag >= deadZone)
					{
						joy_analog_x[wm->unid] = cc->ljs.rx;
						joy_analog_y[wm->unid] = cc->ljs.ry;

						float v = cc->ljs.ang;

						if(STICK2WAY)
						{
							if( v < 180){
								joyExKey |= GP2X_RIGHT;
								//printf("Right\n");
							}
							else if ( v >= 180){
								joyExKey |= GP2X_LEFT;
								//printf("Left\n");
							}
						}
						else if(STICK4WAY)
						{
							if(v >= 315 || v < 45){
								joyExKey |= GP2X_UP;
								//printf("Up\n");
							}
							else if (v >= 45 && v < 135){
								joyExKey |= GP2X_RIGHT;
								//printf("Right\n");
							}
							else if (v >= 135 && v < 225){
								joyExKey |= GP2X_DOWN;
								//printf("Down\n");
							}
							else if (v >= 225 && v < 315){
								joyExKey |= GP2X_LEFT;
								//printf("Left\n");
							}
						}
						else
						{
							if( v >= 330 || v < 30){
								joyExKey |= GP2X_UP;
								//printf("Up\n");
							}
							else if ( v >= 30 && v <60  )  {
								joyExKey |= GP2X_UP;joyExKey |= GP2X_RIGHT;
								//printf("UpRight\n");
							}
							else if ( v >= 60 && v < 120  ){
								joyExKey |= GP2X_RIGHT;
								//printf("Right\n");
							}
							else if ( v >= 120 && v < 150  ){
								joyExKey |= GP2X_RIGHT;joyExKey |= GP2X_DOWN;
								//printf("RightDown\n");
							}
							else if ( v >= 150 && v < 210  ){
								joyExKey |= GP2X_DOWN;
								//printf("Down\n");
							}
							else if ( v >= 210 && v < 240  ){
								joyExKey |= GP2X_DOWN;joyExKey |= GP2X_LEFT;
								//printf("DownLeft\n");
							}
							else if ( v >= 240 && v < 300  ){
								joyExKey |= GP2X_LEFT;
								//printf("Left\n");
							}
							else if ( v >= 300 && v < 330  ){
								joyExKey |= GP2X_LEFT;
								joyExKey |= GP2X_UP;
								//printf("LeftUp\n");
							}
						}
					}

					if(cc->rjs.mag >= deadZone)
					{
						float v = cc->rjs.ang;

						if( v >= 330 || v < 30){
						   joyExKey |= GP2X_Y;
						   //printf("Y\n");
						}
						else if ( v >= 30 && v <60  )  {
						   joyExKey |= GP2X_Y;joyExKey |= GP2X_B;
						   //printf("Y B\n");
						}
						else if ( v >= 60 && v < 120  ){
							joyExKey |= GP2X_B;
							//printf("B\n");
						}
						else if ( v >= 120 && v < 150  ){
							joyExKey |= GP2X_B;joyExKey |= GP2X_X;
							//printf("B X\n");
						}
						else if ( v >= 150 && v < 210  ){
							joyExKey |= GP2X_X;
							//printf("X\n");
						}
						else if ( v >= 210 && v < 240  ){
							joyExKey |= GP2X_X;joyExKey |= GP2X_A;
							//printf("X A\n");
						}
						else if ( v >= 240 && v < 300  ){
							joyExKey |= GP2X_A;
							//printf("A\n");
						}
						else if ( v >= 300 && v < 330  ){
							joyExKey |= GP2X_A;joyExKey |= GP2X_Y;
							//printf("A Y\n");
						}
					}

/*
					printf("classic L button pressed:         %f\n", cc->l_shoulder);
					printf("classic R button pressed:         %f\n", cc->r_shoulder);
					printf("classic left joystick angle:      %f\n", cc->ljs.ang);
					printf("classic left joystick magnitude:  %f\n", cc->ljs.mag);
					printf("classic right joystick angle:     %f\n", cc->rjs.ang);
					printf("classic right joystick magnitude: %f\n", cc->rjs.mag);
*/
				}



		return joyExKey;
	 } else {
		joyExKey = 0;
		return joyExKey;
	 }
}


