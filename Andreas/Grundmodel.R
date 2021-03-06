
library(forecast)
library(tidyverse)
library(Quandl)
library(tseries)
library(vars)
#devtools::install_github("mbalcilar/mFilter")
library(mFilter)

key <- "WB3WH-RUprDSyH2xaLbu"

th <- theme(plot.title        = element_text(size = 20),
            plot.background   = element_rect(fill = "white", color = NA),
            panel.background  = element_rect(fill = NA,       color = NA), 
            legend.background = element_rect(fill = NA,       color = NA),
            legend.key        = element_rect(fill = NA,       color = NA),
            strip.background  = element_rect(fill = NA,       color = NA),
            panel.border      = element_rect(fill = NA,       color = "black", size = 0.3),
            panel.grid        = element_line(color = NA),
            title             = element_text(color = "black"),
            plot.subtitle     = element_text(color = "grey40"),
            plot.caption      = element_text(color = "grey70"),
            strip.text        = element_text(face  = "bold"),
            axis.text         = element_text(color = "black"),
            axis.ticks        = element_line(color = "black"),
            plot.margin       = unit(c(0.2, 0.1, 0.2, 0.1), "cm"))

# Data 1959-2019--------------------------------------------------------------------
FFR <- Quandl("FRED/FEDFUNDS", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date) %>% 
  dplyr::select(Value)

CPI <- Quandl("FRED/CPIAUCSL", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date) %>% 
  dplyr::select(Value)

PROD <- Quandl("FRED/INDPRO", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date) %>% 
  dplyr::select(Value)


# Extra data --------------------------------------------------------------
COM <- Quandl("FRED/PPIIDC", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date) %>% 
  dplyr::select(Value)

bond <- Quandl("FED/SVENY", collapse = "m", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date)

SPREAD <- data.frame(Value = c(rnorm(28, mean = 0.4,sd = 0.1),bond$SVENY05 - bond$SVENY02))

DOW <- read_delim("//student.aau.dk/Users/lbni13/Desktop/DOW2.csv", ";", 
                  escape_double = FALSE, locale = locale(decimal_mark = ","), 
                  trim_ws = TRUE) %>% 
  rename(Value = `US DOW JONES INDUSTRIALS SHARE PRICE INDEX (EP) NADJ`) %>% 
  dplyr::select(Value)

<<<<<<< HEAD
adf.test(COM)
=======
gap <- PROD %>% 
  ts(start = 1959) %>% 
  log() %>% 
  hpfilter(freq=129600)
>>>>>>> 8e1429eafc9dccd4f7d5cbcc56f2eed254fba104

GAP <- data.frame(Value = as.numeric(gap$cycle))

SHA <- Quandl("SHADOWS/US") %>% 
  filter(Date >= "2000-01-01", Date < "2016-01-01") %>% 
  arrange(Date) %>% 
  dplyr::select(`Policy Rate`)


<<<<<<< HEAD
Data <-  cbind(dCPI,dPROD,dFFR) #Grundmodel
Data1 <- cbind(dCPI,dCOM,dPROD,dFFR) #Grundmodel + commodity
Data2 <- cbind(dCPI,dDOW,dPROD,dFFR) #Grundmodel + aktie (D&J)
Data3 <- cbind(dCPI,cyc,dFFR) #Grundmodel + outputgap
Data4 <- cbind(dCPI,SPREAD2,dPROD,dFFR) #Grundmodel + Spread
=======


# Stationæritet-test  ----------------------------------------------------
adf.test(FFR$Value)
adf.test(CPI$Value)
adf.test(PROD$Value)
adf.test(DOW$Value)
adf.test(COM$Value)
adf.test(SPREAD$Value)
adf.test(GAP$Value)

dFFR   <- data.frame(FFR  = diff(FFR$Value))
dCPI   <- data.frame(CPI  = diff(log(CPI$Value))*100)
dPROD  <- data.frame(PROD = diff(log(PROD$Value))*100)
dDOW   <- data.frame(DOW  = diff(log(DOW$Value))*100)
dCOM   <- data.frame(COM  = diff(log(COM$Value))*100)
SPREAD <- data.frame(SPREAD = SPREAD$Value)
dSHA    <- data.frame(SHA = diff(SHA))

# Datasæt til model-------------------------------------------------------
Data0 <- data.frame(dCPI,          dPROD, dFFR) #Grundmodel
Data1 <- data.frame(dCPI, dCOM,    dPROD, dFFR) #Grundmodel + commodity
Data2 <- data.frame(dCPI, dDOW,    dPROD, dFFR) #Grundmodel + aktie (D&J)
Data3 <- data.frame(dCPI, GAP = GAP[-1,], dFFR) #Grundmodel + outputgap
Data4 <- data.frame(dCPI, SPREAD,  dPROD, dFFR) #Grundmodel + Spread
>>>>>>> 8e1429eafc9dccd4f7d5cbcc56f2eed254fba104

# Modeller  --------------------------------------------------------------
V0 <- VAR(Data0, p = 13)
V1 <- VAR(Data1, p = 13)
V2 <- VAR(Data2, p = 13)
V3 <- VAR(Data3, p = 13)
V4 <- VAR(Data4, p = 13)


irf0 <- irf(V0, impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48, ci = 0.66)
irf1 <- irf(V1, impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48, ci = 0.66)
irf2 <- irf(V2, impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48, ci = 0.66)
irf3 <- irf(V3, impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48, ci = 0.66)
irf4 <- irf(V4, impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48, ci = 0.66)




# Plot af modeller --------------------------------------------------------

p0 <- rbind(irf0$irf$FFR   %>% as_tibble %>% mutate(type = "irf", N = 1:49),
      irf0$Upper$FFR %>% as_tibble %>% mutate(type = "upper", N = 1:49),
      irf0$Lower$FFR %>% as_tibble %>% mutate(type = "lower", N = 1:49)) %>% as_tibble %>% mutate(model = "Benchmark Model")
p0

p1 <- rbind(irf1$irf$FFR   %>% as_tibble %>% mutate(type = "irf", N = 1:49),
            irf1$Upper$FFR %>% as_tibble %>% mutate(type = "upper", N = 1:49),
            irf1$Lower$FFR %>% as_tibble %>% mutate(type = "lower", N = 1:49)) %>% as_tibble %>% mutate(model = "Commoditie Prices")


rbind(p1,p0) %>% 
  ggplot(aes(N, CPI, linetype=type)) + 
  geom_hline(aes(yintercept = 0), color="grey") +
  geom_line() + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_y_continuous(limits=c(-0.02,0.06)) + 
  scale_x_continuous("Lags (months)", limits = c(0,48), breaks = seq(0, 48, 8)) +
  facet_wrap(~model) + 
  th + theme(axis.title.y = element_blank(), legend.position = "none")



p2 <- rbind(irf2$irf$FFR   %>% as_tibble %>% mutate(type = "irf", N = 1:49),
            irf2$Upper$FFR %>% as_tibble %>% mutate(type = "upper", N = 1:49),
            irf2$Lower$FFR %>% as_tibble %>% mutate(type = "lower", N = 1:49)) %>% as_tibble %>% mutate(model = "Dow Jones")


rbind(p2,p0) %>% 
  ggplot(aes(N, CPI, linetype=type)) + 
  geom_hline(aes(yintercept = 0), color="grey") +
  geom_line() + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_y_continuous(limits=c(-0.02,0.06)) + 
  scale_x_continuous("Lags (months)", limits = c(0,48), breaks = seq(0, 48, 8)) +
  facet_wrap(~model) + 
  th + theme(axis.title.y = element_blank(), legend.position = "none")



p3 <- rbind(irf3$irf$FFR   %>% as_tibble %>% mutate(type = "irf", N = 1:49),
            irf3$Upper$FFR %>% as_tibble %>% mutate(type = "upper", N = 1:49),
            irf3$Lower$FFR %>% as_tibble %>% mutate(type = "lower", N = 1:49)) %>% as_tibble %>% mutate(model = "Output Gap")


rbind(p3,p0) %>% 
  ggplot(aes(N, CPI, linetype=type)) + 
  geom_hline(aes(yintercept = 0), color="grey") +
  geom_line() + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_y_continuous(limits=c(-0.02,0.06)) + 
  scale_x_continuous("Lags (months)", limits = c(0,48), breaks = seq(0, 48, 8)) +
  facet_wrap(~model) + 
  th + theme(axis.title.y = element_blank(), legend.position = "none")


p4 <- rbind(irf4$irf$FFR   %>% as_tibble %>% mutate(type = "irf", N = 1:49),
            irf4$Upper$FFR %>% as_tibble %>% mutate(type = "upper", N = 1:49),
            irf4$Lower$FFR %>% as_tibble %>% mutate(type = "lower", N = 1:49)) %>% as_tibble %>% mutate(model = "Yield Curve Spread")


rbind(p4,p0) %>% 
  ggplot(aes(N, CPI, linetype=type)) + 
  geom_hline(aes(yintercept = 0), color="grey") +
  geom_line() + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_y_continuous(limits=c(-0.02,0.06)) + 
  scale_x_continuous("Lags (months)", limits = c(0,48), breaks = seq(0, 48, 8)) +
  facet_wrap(~model) + 
  th + theme(axis.title.y = element_blank(), legend.position = "none")





# GGPLOT ------------------------------------------------------------------

FFR2 <- Quandl("FRED/FEDFUNDS", api_key = key) %>% 
  filter(Date >= "2000-01-01", Date < "2015-12-01") %>% 
  arrange(Date)

SHA2 <- Quandl("SHADOWS/US", api_key = key) %>% 
  filter(Date >= "2000-01-01", Date < "2016-01-01") %>% 
  arrange(Date)

CPI2 <- Quandl("FRED/CPIAUCSL", api_key = key) %>% 
  filter(Date >= "2000-01-01", Date < "2015-12-01") %>% 
  arrange(Date)

PROD2 <- Quandl("FRED/INDPRO", api_key = key) %>% 
  filter(Date >= "2000-01-01", Date < "2015-12-01") %>% 
  arrange(Date)

FFR2 <- FFR2$Value
SHA2 <- SHA2$`Policy Rate`
CPI2 <- CPI2$Value
PROD2 <- PROD2$Value

dFFR2 <- diff(FFR2)
dSHA2 <- diff(SHA2)
dCPI2 <- diff(log(CPI2))*100
dPROD2 <- diff(log(PROD2))*100

Data0 <- cbind(dCPI2,dPROD2,dFFR2) #Grundmodel
Data1 <- cbind(dCPI2,dPROD2,dSHA2) #Negativ model


V <- VAR(Data0, p=3)
irf_FFR <- irf(V, impulse = "dFFR2", response = "dCPI2", ortho = T, cumulative = F, n.ahead = 24, ci=0.66)

V1 <- VAR(Data1, p=3)
irf_SHA <- irf(V1, impulse = "dSHA2", response = "dCPI2", ortho = T, cumulative = F, n.ahead = 24, ci=0.66)



SHA2a <- SHA2 %>% as_tibble %>% mutate(type="SHA", n=seq(from=as.Date("2000-01-01"), to =as.Date("2015-11-01"), by="months"))
FFR2a <- FFR2 %>% as_tibble %>% mutate(type="FFR", n=seq(from=as.Date("2000-01-01"), to =as.Date("2015-11-01"), by="months"))
negativ <- rbind(FFR2a,SHA2a)

negativ %>% 
  as_tibble %>% 
  ggplot(aes(n, value, linetype=type)) + 
  geom_line() + 
  geom_hline(aes(yintercept=0),linetype="solid", color="grey") + 
  scale_linetype_manual(labels=c("Federal Funds\nRate", "Shaddow Rate"), values=c("solid", "dotted"), name="Type") +
  th + theme(axis.title = element_blank())

irf_FFR1 <- irf_FFR$irf$dFFR
irf_FFR2 <- irf_FFR$Lower$dFFR
irf_FFR3 <- irf_FFR$Upper$dFFR

samligning_FFR <- cbind(irf_FFR1,irf_FFR2,irf_FFR3) %>% as_tibble  %>% mutate(type="Federal Funds Rate") %>% mutate(n=c(1:25))
samligning1 <- samligning_FFR %>% gather(variable, value, -type)

irf_SHA1 <- irf_SHA$irf$dSHA
irf_SHA2 <- irf_SHA$Lower$dSHA
irf_SHA3 <- irf_SHA$Upper$dSHA

samligning_SHA <- cbind(irf_SHA1,irf_SHA2,irf_SHA3) %>% as_tibble  %>% mutate(type="Shadow Rate") %>% mutate(n=c(1:25))
samligning2 <- samligning_SHA %>% gather(variable, value, -type)


samligning <- rbind(samligning_FFR,samligning_SHA)

<<<<<<< HEAD
VARselect(Data, lag.max = 24)
V <- VAR(Data, p=13)
irf <- irf(V, impulse = "dFFR", response = "dFFR", ortho = T, cumulative = F, n.ahead = 48, ci=0.66)
plot(irf)

VARselect(Data1, lag.max = 24)
V1 <- VAR(Data1, p=13)
irf1 <- irf(V1, impulse = "dFFR", response = "dCPI", ortho = T, cumulative = F, n.ahead = 48, ci=0.66)
plot(irf1)

VARselect(Data2, lag.max = 24)
V2 <- VAR(Data2, p=13)
irf2 <- irf(V2, impulse = "dFFR", response = "dCPI", ortho = T, cumulative = F, n.ahead = 48, ci=0.66)
plot(irf2)

VARselect(Data3, lag.max = 24)
V3 <- VAR(Data3, p=13)
irf3 <- irf(V3, impulse = "dFFR", response = "dCPI", ortho = T, cumulative = F, n.ahead = 48, ci=0.66)
plot(irf3)

VARselect(Data4, lag.max = 24)
V4 <- VAR(Data4, p=13)
irf4 <- irf(V4, impulse = "dFFR", response = "dCPI", ortho = T, cumulative = F, n.ahead = 48)
plot(irf4)

# TEST af rækkefølge --------------------------------------------------------------------

irf1 <-  irf(VAR(Data2[,c(1,2,3,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf2 <-  irf(VAR(Data2[,c(1,2,4,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf3 <-  irf(VAR(Data2[,c(1,3,4,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf4 <-  irf(VAR(Data2[,c(1,3,2,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf5 <-  irf(VAR(Data2[,c(1,4,2,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf6 <-  irf(VAR(Data2[,c(1,4,3,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)

irf7 <-  irf(VAR(Data2[,c(2,1,3,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf8 <-  irf(VAR(Data2[,c(2,1,4,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf9 <-  irf(VAR(Data2[,c(2,3,4,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf10 <- irf(VAR(Data2[,c(2,3,1,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf11 <- irf(VAR(Data2[,c(2,4,3,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf12 <- irf(VAR(Data2[,c(2,4,1,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)

irf13 <- irf(VAR(Data2[,c(3,1,2,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf14 <- irf(VAR(Data2[,c(3,1,4,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf15 <- irf(VAR(Data2[,c(3,2,1,4)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf16 <- irf(VAR(Data2[,c(3,2,4,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf17 <- irf(VAR(Data2[,c(3,4,1,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf18 <- irf(VAR(Data2[,c(3,4,2,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)

irf19 <- irf(VAR(Data2[,c(4,1,2,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf20 <- irf(VAR(Data2[,c(4,1,3,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf21 <- irf(VAR(Data2[,c(4,2,1,3)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf22 <- irf(VAR(Data2[,c(4,2,3,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf23 <- irf(VAR(Data2[,c(4,3,1,2)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)
irf24 <- irf(VAR(Data2[,c(4,3,2,1)], p=13), impulse = "FFR", response = "CPI", ortho = T, cumulative = F, n.ahead = 48)

a <- cbind(irf1$irf$FFR,
           irf2$irf$FFR,
           irf3$irf$FFR,
           irf4$irf$FFR,
           irf5$irf$FFR,
           irf6$irf$FFR,
           irf7$irf$FFR,
           irf8$irf$FFR,
           irf9$irf$FFR,
           irf10$irf$FFR,
           irf11$irf$FFR,
           irf12$irf$FFR,
           irf13$irf$FFR,
           irf14$irf$FFR,
           irf15$irf$FFR,
           irf16$irf$FFR,
           irf17$irf$FFR,
           irf18$irf$FFR,
           irf19$irf$FFR,
           irf20$irf$FFR,
           irf21$irf$FFR,
           irf22$irf$FFR,
           irf23$irf$FFR,
           irf24$irf$FFR)

a %>% as_tibble %>% mutate(n=c(1:49)) %>% gather(variable, value, -n) %>% ggplot(aes(n, value, group=variable, color=variable)) + geom_line()
a
=======
samligning %>% gather(variable, value, -type, -n) %>% 
  ggplot(aes(n, value, linetype=variable))+ 
  geom_hline(aes(yintercept=0), linetype="solid", color="grey") + 
  geom_line(size=0.6, show.legend = FALSE) + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  facet_wrap(~type) + 
  th  + theme(axis.title = element_blank())
>>>>>>> 8e1429eafc9dccd4f7d5cbcc56f2eed254fba104
