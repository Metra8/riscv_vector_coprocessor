# Reloj ajustado a 80 MHz para margen de timing con TMR
create_clock -period 12.500 -name clk_virtual [get_ports clk_i]

# Actividad de conmutación
set_switching_activity -default_toggle_rate 20.000 -default_static_probability 0.500