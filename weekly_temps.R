# ICA 16: Using git with R Projects
# Junjie Cai

days <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
temps_f <- c(62, 68, 71, 75, 70, 66, 64)

weekly <- data.frame(
  day = days,
  temp_f = temps_f
)

weekly$temp_c <- round((weekly$temp_f - 32) * 5 / 9, 1)

mean_f <- mean(weekly$temp_f)
warmest <- weekly$day[which.max(weekly$temp_f)]

print(weekly)
cat("Mean temperature (F):", round(mean_f, 1), "\n")
cat("Warmest day:", warmest, "\n")
