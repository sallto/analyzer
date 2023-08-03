// PARAM: --enable ana.race.direct-arithmetic --set ana.activated[+] "'var_eq'"
#include<stdio.h>
//#include <goblint.h>

extern int get();
int main() {
  int x=5;
  int z;
  int y=get();
  if(y){
    z=5;
  }else{
    z=6;
  }
  return z;
}
