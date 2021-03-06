
# Script to calculate simple VAR model ------------------------------------
# 
# Lars, Andreas og Jens
# Redigeret: 26-03-19
# 
# 
#
# Packages ----------------------------------------------------------------

library(forecast)
library(tidyverse)
library(Quandl)
library(tseries)
library(vars)
library(xtable)
library(RColorBrewer)

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


# Data --------------------------------------------------------------------

FFR <- Quandl("FRED/FEDFUNDS", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date)

CPI <- Quandl("FRED/CPIAUCSL", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date)

PROD <- Quandl("FRED/INDPRO", api_key = key) %>% 
  filter(Date >= "1959-01-01", Date < "2019-01-01") %>% 
  arrange(Date)



# Model -------------------------------------------------------------------

# Ordering 1. Inflation, 2. Output, 3. Federal Funds Rate 
# Remember the first is most exogenious
pp <- data.frame(Date = FFR$Date[-1],
                 INFL = diff(log(CPI$Value))*100,
                 PROD = diff(log(PROD$Value))*100,
                 FFR  = diff(FFR$Value))

# Decide number of lags in VAR model
VARselect(pp[,c(2:4)], lag.max = 24, type = c("const", "trend", "both", "none"))$selection

# Check for stationarity
rbind(adf.test(FFR$Value), adf.test(CPI$Value), adf.test(PROD$Value))
rbind(adf.test(pp$FFR),    adf.test(pp$INFL),   adf.test(pp$PROD))



pp$type <- "Transformeret"

p1 <- tibble(Date = FFR$Date, FFR = FFR$Value, INFL = CPI$Value, PROD = PROD$Value) %>% 
  mutate(type = "Utransformeret") %>% 
  rbind(.,pp) %>% 
  mutate(type = factor(.$type, levels= c("Utransformeret", "Transformeret"))) %>% 
  gather(variable, value, -Date, -type) %>% 
  ggplot(aes(Date, value)) + 
  geom_line(size = 0.3) + 
  facet_grid(type~variable, scale="free") +
  labs(x = "", y = "") +
  th + theme(axis.title=element_blank())


ggsave(plot = p1, filename = "GENERATE/VAR1.pdf", width = 24, height = 8, units = "cm", dpi = 320)

# VAR(1) model ------------------------------------------------------------

model <- VAR(pp[,c(2:4)], p = 1, type = "const", ic = c("AIC", "HQ", "SC", "FPE"))

# stargazer::stargazer(model$varresult$FFR, 
#                      model$varresult$INFL, 
#                      model$varresult$PROD, 
#                      title="VAR(1) summary statistics", 
#                      no.space = TRUE, align=TRUE)


# VAR(13) model -----------------------------------------------------------

m <- VAR(pp[,c(2:4)], p = 13)

data <- irf(m, n.ahead = 49, cumulative = F, ci = 0.66)
variables <- data$irf %>% names

ir <- lapply(1:length(variables), function(e){
  data_to_plot <- data.frame(data %>% `$`(irf) %>% `[[`(variables[e])) %>%
    mutate("t" = 1:NROW(.)) %>%
    gather(.,Variable, Value, -t)
  
  upper_ci <- data.frame(data %>% `$`(Upper) %>% `[[`(variables[e])) %>%
    mutate("t" = 1:NROW(.)) %>%
    gather(.,Variable, Upper, -t)
  
  lower_ci <- data.frame(data %>% `$`(Lower) %>% `[[`(variables[e]) ) %>%
    mutate("t" = 1:NROW(.)) %>%
    gather(.,Variable, Lower, -t)
  
  res <- inner_join(data_to_plot, upper_ci, c("t","Variable")) %>%
    inner_join(.,lower_ci, c("t","Variable")) %>%
    mutate(impulse = paste("Shock to", variables[e])) 
}) %>% bind_rows

ir$t <- ir$t-1

ir$Variable <- fct_relevel(ir$Variable, "INFL", "PROD")
ir$impulse <- fct_relevel(ir$impulse, "Shock to INFL", "Shock to PROD")

p2 <- ggplot(ir, aes(x = t, y = Value, group = Variable))  +
  geom_hline(aes(yintercept=0),linetype="solid", color="grey") +
  geom_line(size = 0.3) +
  geom_line(aes(x = t, y = Upper), linetype = "dotted", size = 0.3) +
  geom_line(aes(x = t, y = Lower), linetype = "dotted", size = 0.3) +
  scale_x_continuous("Lags (months)", limits = c(0,48), breaks = seq(0, 48, 6)) +
  scale_y_continuous("Percent\n ", position = "right", limits = c(-0.4,1), breaks = c(-0.1,-0.05,0,0.05,0.10,0.15)) +
  facet_grid(Variable ~ impulse, switch = "y") +
  coord_cartesian(ylim = c(-0.1, 0.15)) +
  th

ggsave(plot = p2, filename = "GENERATE/VAR2.pdf", width = 24, height = 14, units = "cm", dpi = 320)

# Variance decomposition --------------------------------------------------
# 
# fe <- fevd(m, n.ahead = 12)
# 
# xtable(cbind(round(fe$INFL[c(1,4,8,12),],2)*100,
#              round(fe$PROD[c(1,4,8,12),],2)*100,
#              round(fe$FFR[c(1,4,8,12),],2)*100))
# 




# Different orderings of variables ----------------------------------------

or1 <- irf(VAR(pp[c(1,2,3,4)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)
or2 <- irf(VAR(pp[c(1,2,4,3)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)
or3 <- irf(VAR(pp[c(1,3,2,4)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)
or4 <- irf(VAR(pp[c(1,3,4,2)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)
or5 <- irf(VAR(pp[c(1,4,2,3)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)
or6 <- irf(VAR(pp[c(1,4,3,2)][,c(2:4)], p = 13), impulse = "FFR", response = "INFL", n.ahead = 48, ci = 0.66)

df <- tibble(R1 = as.vector(or1$irf$FFR),
             R2 = as.vector(or2$irf$FFR),
             R3 = as.vector(or3$irf$FFR),
             R4 = as.vector(or4$irf$FFR),
             R5 = as.vector(or5$irf$FFR),
             R6 = as.vector(or6$irf$FFR),
             N  = c(0:48),
             inte = "base") %>% gather(variable, Change, -N, -inte)

df1 <- tibble(R1 = as.vector(or1$Upper$FFR),
              R2 = as.vector(or2$Upper$FFR),
              R3 = as.vector(or3$Upper$FFR),
              R4 = as.vector(or4$Upper$FFR),
              R5 = as.vector(or5$Upper$FFR),
              R6 = as.vector(or6$Upper$FFR),
              N  = c(0:48),
              inte = "upper") %>% gather(variable, Change, -N, -inte)

df2 <- tibble(R1 = as.vector(or1$Lower$FFR),
              R2 = as.vector(or2$Lower$FFR),
              R3 = as.vector(or3$Lower$FFR),
              R4 = as.vector(or4$Lower$FFR),
              R5 = as.vector(or5$Lower$FFR),
              R6 = as.vector(or6$Lower$FFR),
              N  = c(0:48),
              inte = "Lower") %>% gather(variable, Change, -N, -inte)

p3 <- rbind(df,df1,df2) %>% 
  group_by(variable, inte) %>% 
  mutate(Accumulated = cumsum(Change)) %>% 
  gather(type, value, -N, -variable, -inte) %>% 
  ggplot(aes(N, value, color = variable, linetype=inte)) + 
  facet_wrap(~type, scales = "free") +
  geom_hline(aes(yintercept = 0), color="grey") +
  geom_line(size = 0.3) + 
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_color_manual(values = c("black","black","black","black","black","black","black")) +
  scale_x_continuous(breaks = seq(0,48, by = 6), limits = c(0, 48)) +
  labs(linetype = "Order", y = "", x = "Lags (months)") +
  th + theme(axis.title.y=element_blank(), legend.position = "none")

ggsave(plot = p3, filename = "GENERATE/VAR3.pdf", width = 24, height = 6, units = "cm", dpi = 320)




# Test of struktural shifts -----------------------------------------------



Martin    <- pp %>% filter(Date > "1951-01-01", Date < "1970-02-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)
Burns     <- pp %>% filter(Date > "1970-02-01", Date < "1979-08-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)
Volcker   <- pp %>% filter(Date > "1979-08-01", Date < "1987-08-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)
Greenspan <- pp %>% filter(Date > "1987-08-01", Date < "2006-01-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)
Bernanke  <- pp %>% filter(Date > "2006-01-01", Date < "2014-01-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)
Yellen    <- pp %>% filter(Date > "2014-01-01", Date < "2018-02-01") %>% dplyr::select(-Date, -type) %>% VAR(p = 5) %>% irf(impulse = "FFR", response = "INFL", n.ahead = 24, ci = 0.66)



df <- rbind(tibble(IRF = Martin$irf$FFR[,1],    Lower = Martin$Lower$FFR[,1],    Upper = Martin$Upper$FFR[,1],    N = c(0:24), type = "Martin\n1959 - 1970"),
            tibble(IRF = Burns$irf$FFR[,1],     Lower = Burns$Lower$FFR[,1],     Upper = Burns$Upper$FFR[,1],     N = c(0:24), type = "Burns\n1970 - 1978"),
            tibble(IRF = Volcker$irf$FFR[,1],   Lower = Volcker$Lower$FFR[,1],   Upper = Volcker$Upper$FFR[,1],   N = c(0:24), type = "Volcker\n1979 - 1987"),
            tibble(IRF = Greenspan$irf$FFR[,1], Lower = Greenspan$Lower$FFR[,1], Upper = Greenspan$Upper$FFR[,1], N = c(0:24), type = "Greenspan\n1987 - 2006"),
            tibble(IRF = Bernanke$irf$FFR[,1],  Lower = Bernanke$Lower$FFR[,1],  Upper = Bernanke$Upper$FFR[,1],  N = c(0:24), type = "Bernanke\n2006 - 2014"),
            tibble(IRF = Yellen$irf$FFR[,1],    Lower = Yellen$Lower$FFR[,1],    Upper = Yellen$Upper$FFR[,1],    N = c(0:24), type = "Yellen\n2014 - 2018")) %>% 
  gather(variable, value, -type, -N)

df$type <- factor(df$type, levels = c("Martin\n1951 - 1970", "Burns\n1970 - 1978", "Volcker\n1979 - 1987","Greenspan\n1987 - 2006","Bernanke\n2006 - 2014","Yellen\n2014 - 2018"))

p4 <- df %>% ggplot(aes(N, value, linetype = variable)) +  
  geom_hline(aes(yintercept = 0), size = 0.5, color="grey") +
  geom_line(size = 0.3)+
  facet_wrap(~type) +
  scale_linetype_manual(values = c("solid", "dotted", "dotted")) + 
  scale_y_continuous(breaks = c(0.10,0.05,0,-0.05,-0.10), limits = c(-0.19, 0.19)) +
  scale_x_continuous("Lags (months)", limits = c(0,24), breaks = seq(0, 24, 4)) +
  coord_cartesian(ylim = c(-0.12, 0.12)) +
  labs(y="", x="Lags (months)", linetype = "") +
  th + theme(axis.title.y=element_blank(), legend.position = "none")

ggsave(plot = p4, filename = "GENERATE/VAR4.pdf", width = 24, height = 12, units = "cm", dpi = 320)



# Forecasting -------------------------------------------------------------

# actual <- pp %>% 
#   filter(Date >= "2018-01-01") %>% 
#   mutate(TYPE = "Actual") %>% 
#   dplyr::select(-type)
# 
# dat <- pp %>% filter(Date < "2018-01-01")
# 
# 
# m <- auto.arima(dat$INFL)
# infl.arima <- predict(m, n.ahead = 12)
# 
# m <- auto.arima(dat$PROD)
# prod.arima <- predict(m, n.ahead = 12)
# 
# m <- auto.arima(dat$FFR)
# ffr.arima <- predict(m, n.ahead = 12)
# 
# 
# arima <- tibble(Date = actual$Date,
#                 FFR = ffr.arima$pred,
#                 INFL = infl.arima$pred,
#                 PROD = prod.arima$pred, 
#                 TYPE = "ARIMA")
# 
# m <- pp %>% 
#   filter(Date < "2018-01-01") %>% 
#   dplyr::select(-Date, -type) %>% 
#   VAR(p = 13)
# 
# pred <- predict(m, n.ahead = 12)
# 
# prediction <- tibble(Date = actual$Date,
#                      INFL = pred$fcst$INFL[,1],
#                      FFR = pred$fcst$FFR[,1],
#                      PROD = pred$fcst$PROD[,1], 
#                      TYPE = "VAR")
# 
# 
# rbind(actual, prediction, arima) %>% 
#   gather(variable, value, -Date, -TYPE) %>% 
#   ggplot(aes(Date, value, linetype=TYPE)) +
#   geom_line() +
#   facet_wrap(~variable) + 
#   labs(linetype="Model") +
#   th + theme(axis.title=element_blank())



# RMSE --------------------------------------------------------------------

# RMSE = function(m, o){
#   sqrt(mean((m - o)^2))
# }
# 
# RMSE(pred$fcst$INFL[,1], actual$INFL)
# RMSE(infl.arima$pred, actual$INFL)
# 
# RMSE(pred$fcst$FFR[,1], actual$FFR)
# RMSE(ffr.arima$pred, actual$FFR)
# 
# RMSE(pred$fcst$PROD[,1], actual$PROD)
# RMSE(prod.arima$pred, actual$PROD)
# 
# 
# 
# cor(FAVAR_T$IPMANSICS, FAVAR_PCA$x[,1])




# Granger -----------------------------------------------------------------

# grangertest(x = pp$INFL, y = pp$PROD, order = 13)
# grangertest(x = pp$INFL, y = pp$FFR, order = 13)
# 
# grangertest(x = pp$PROD, y = pp$INFL, order = 13)
# grangertest(x = pp$PROD, y = pp$FFR, order = 13)
# 
# grangertest(x = pp$FFR, y = pp$INFL, order = 13)
# grangertest(x = pp$FFR, y = pp$PROD, order = 13)

# Persp plot ---------------------------------------------------------------
# 
# n.columns <- 598 # 718m - 72m  Time difference of 45.32564 mins
# irff <- matrix(nrow = 44, ncol = n.columns)
# 
# start_time <- Sys.time()
# for (i in 1:n.columns) {
#   result <- pp %>% 
#     filter(Date > as.Date("1960-02-01") %m+% months(i) & Date < as.Date("1960-02-01") %m+% months(120 + i)) %>% 
#     dplyr::select(-Date) %>% VAR(p = 2)
#   irff[,i] <- irf(result, impulse = "FFR", response = "INFL", n.ahead = 43)$irf$FFR
# }
# end_time <- Sys.time()
# end_time - start_time
# 
# x <- c(1:44)
# y <- seq(1970, 2019, length.out = 598)
# z <- irff
# 
# # Create a function interpolating colors in the range of specified colors
# jet.colors <- colorRampPalette(brewer.pal(9,"YlGnBu"))
# 
# # Generate the desired number of colors from this palette
# nbcol <- 100
# color <- jet.colors(nbcol)
# 
# # Compute the z-value at the facet centres
# zfacet <- (z[-1, -1] + z[-1, -ncol(z)] + z[-nrow(z), -1] + z[-nrow(z), -ncol(z)])/4
# 
# # Recode facet z-values into color indices
# facetcol <- cut(zfacet, nbcol)
# 
# a <- persp(x, y, z, col = color[facetcol],
#            zlim = c(-0.10, 0.15),
#            xlab = "Months", ylab = "", zlab = "%",
#            theta = 40, phi = 30, expand = 0.45,
#            ticktype = "detailed", lwd = 0.1)
# 
# text(trans3d(0, 1970.0, 0.145, a), "Burns",     col = "black")
# text(trans3d(0, 1979.8, 0.145, a), "Volcker",   col = "black")
# text(trans3d(0, 1987.8, 0.145, a), "Greenspan", col = "black")
# text(trans3d(0, 2006.0, 0.145, a), "Bernanke",  col = "black")
# text(trans3d(0, 2014.0, 0.145, a), "Yellen",    col = "black")
# 
# lines(trans3d(x = 0, y = 1970, z = c(0.13,-0.01),  pmat = a), lwd = 0.2, lty = 2,  col = "black")
# lines(trans3d(x = 0, y = 1979, z = c(0.13, 0.045), pmat = a), lwd = 0.2, lty = 2,  col = "black")
# lines(trans3d(x = 0, y = 1987, z = c(0.13, 0.05),  pmat = a), lwd = 0.2, lty = 2,  col = "black")
# lines(trans3d(x = 0, y = 2006, z = c(0.13, 0.01),  pmat = a), lwd = 0.2, lty = 2,  col = "black")
# lines(trans3d(x = 0, y = 2014, z = c(0.13, 0.04),  pmat = a), lwd = 0.2, lty = 2,  col = "black")
# 
