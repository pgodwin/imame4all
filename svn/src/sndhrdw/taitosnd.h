#ifndef __TAITOSND_H__
#define __TAITOSND_H__


#if 0
/* MASTER (16 bit bus) control functions */
WRITE16_HANDLER( taitosound_port16_lsb_w );
WRITE16_HANDLER( taitosound_comm16_lsb_w );
READ16_HANDLER( taitosound_comm16_lsb_r );

WRITE16_HANDLER( taitosound_port16_msb_w );
WRITE16_HANDLER( taitosound_comm16_msb_w );
READ16_HANDLER( taitosound_comm16_msb_r );
#endif


/* MASTER (8bit bus) control functions */
WRITE_HANDLER( taitosound_port_w );
WRITE_HANDLER( taitosound_comm_w );
READ_HANDLER( taitosound_comm_r );


/* SLAVE (8bit bus) control functions ONLY */
WRITE_HANDLER( taitosound_slave_port_w );
READ_HANDLER( taitosound_slave_comm_r );
WRITE_HANDLER( taitosound_slave_comm_w );


#endif /*__TAITOSND_H__*/
