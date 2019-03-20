#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char const *argv[]) {
  char* match = "\\49";
  char target[30] ="Ola ola ";
  char temp[10] = "";
  sprintf(temp, "%c", (int) strtol(match+1, 0, 16));
  strcat(target, temp);
  printf("%s\n", target);

  return 0;
}
