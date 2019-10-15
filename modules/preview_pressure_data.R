library(tidyverse)
library(forecast)
library(zoo)
library(pastecs)

check_pressure_data = function(f1, f2)
{
  r_pressure <- read.csv(f1)
  #r_activity <- read.csv(f2)
  #r_activity <- r_activity %>% mutate(sec = round(timestamp / 1000)) %>% distinct(sec, .keep_all = T) %>% dplyr::select(-timestamp)
  #r_pressure <- mutate(r_pressure, sec = round(timestamp / 1000)) %>% left_join(r_activity)
  r_pressure <- r_pressure %>% mutate(time = as.POSIXct(timestamp / 1000, origin="1970-01-01", "GMT"), pressure_pascals = pressure * 100, t_exp = timestamp / 1000 - min(timestamp / 1000)) %>% arrange(time)
  p <- ggplot(r_pressure, aes(x=time, y=pressure_pascals)) + geom_line() + theme_bw()
  print(p)
  print(summary(diff(r_pressure$timestamp / 1000)))
  print(summary(diff(r_pressure$pressure)))
  print(min(r_pressure$time))
  print(max(r_pressure$time))
  print(difftime(max(r_pressure$time), min(r_pressure$time), units = 'min'))
  r_pressure
}

r_pressure <- read.csv('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/1/Build4Pressure.csv')
r_activity <- read.csv('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/1/Build4ActivityLog.csv')
r_activity <- r_activity %>% mutate(sec = round(timestamp / 1000)) %>% distinct(sec, .keep_all = T) %>% dplyr::select(-timestamp)
r_pressure <- mutate(r_pressure, sec = round(timestamp / 1000)) %>% left_join(r_activity)
ggplot(r_pressure, aes(x=timestamp, y=pressure)) + geom_line() + geom_point(aes(col=prediction)) + theme_bw()


r_activity_sum <- r_activity %>% group_by(sec) %>% summarise(n_actvities = n_distinct(prediction))
r_activity_sum %>% filter(n_actvities > 1)

check_pressure_data('Datasets/For-Different-Phone-Poses/Hand/TUM_MAY_1_HAND_Pressure.csv')
check_pressure_data('Datasets/For-Different-Phone-Poses/Jacket/TUM_MAY_1_JACKET_Pressure.csv')
check_pressure_data('Datasets/For-Different-Phone-Poses/Random/TUM_MAY_1_RANDOM_Pressure.csv')
check_pressure_data('Datasets/For-Different-Phone-Poses/Swing/TUM_MAY_1_SWINGING_Pressure.csv')
check_pressure_data('Datasets/For-Different-Phone-Poses/Trouser/TUM_MAY_1_TROUser_Pressure.csv')

check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/1/Build4Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/2/Build4_2Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/3/Build4_3Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Adelheidstr.13A/4/Build4_4Pressure.csv')

check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.33/1/Build_1Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.33/2/Build1_2Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.33/3/Build1_3Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.33/4/Build1_4Pressure.csv')

check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.35/1/Build3Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.35/2/Build3_2Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.35/3/Build3_3Pressure.csv')
check_pressure_data('Datasets/For-Outdoor-Indoor-Transition/Agnesstr.35/4/Build3_4Pressure.csv')

check_pressure_data('Datasets/For-Stair-Removal/Fast speed/FastPressure.csv')
check_pressure_data('Datasets/For-Stair-Removal/Normal speed/NormalPressure.csv')
check_pressure_data('Datasets/For-Stair-Removal/Slow speed/SlowPressure.csv')

check_pressure_data('Datasets/For-Number-of-Floors-and-Floor-Altitude/AO-Hotel_Laim/July04/My_AO_JULY04Pressure.csv')
check_pressure_data('Datasets/For-Number-of-Floors-and-Floor-Altitude/AO-Hotel_Laim/June12/My_AO_JUN_12Pressure.csv')
check_pressure_data('Datasets/For-Number-of-Floors-and-Floor-Altitude/AO-Hotel_Laim/June13/My_AO_JUN13Pressure.csv')
r <- check_pressure_data('Datasets/For-Number-of-Floors-and-Floor-Altitude/AO-Hotel_Laim/June19/My_AO_JUN19_1Pressure.csv')
r_walk <- r %>% filter(t_exp <= 650 & t_exp >= 20)
ggplot(r_walk, aes(x=t_exp, y=pressure_pascals)) + geom_line() + theme_bw()
f <- auto.arima(r_walk$pressure_pascals, approximation = F, stepwise = F)
sd(f$residuals)

Box.test(f$residuals, type="Ljung")
f2 <- Arima(r_walk$pressure_pascals, order = c(1,1,1))
f2
Box.test(f2$residuals, type="Ljung")
sd(f2$residuals)

xy <- reglin(r_walk$timestamp / 1000, r_walk$pressure_pascals, deltat = 1)
auto.arima(xy$y)
f3 <- Arima(xy$y, order = c(1, 1, 1))
f3

Box.test(f3$residuals, type="Ljung")
sd(f3$residuals, na.rm = T)

r_walk_sec <- r_walk %>% mutate(sec = round(timestamp / 1000), sec_diff = abs(sec - timestamp / 1000)) %>% group_by(sec) %>% filter(sec_diff == min(sec_diff)) %>% distinct(sec, .keep_all = T)

auto.arima(r_walk_sec$pressure_pascals)
f4 <- Arima(r_walk_sec$pressure_pascals, order = c(1, 1, 1))
f4

Box.test(f4$residuals, type="Ljung")
sd(f4$residuals, na.rm = T)

check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Adelheidstr 13A/1/Build4Pressure.csv')
check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Adelheidstr 13A/2/Build4_2Pressure.csv')
check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Adelheidstr 13A/3/Build4_3Pressure.csv')
check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Adelheidstr 13A/4/Build4_4Pressure.csv')
check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Adelheidstr 13A/5/Build4_5Pressure.csv')



check_pressure_data('Evaluations/Outdoor-Indoor-Transitions/Agness 33/long walk outdoor less indoor/Long_walk_outdoor_onlyPressure.csv')
