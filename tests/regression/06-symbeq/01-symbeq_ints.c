// PARAM: --enable ana.race.direct-arithmetic --set ana.activated[+] "'var_eq'"
#include <stdio.h>
// #include <goblint.h>

int transform(int z)
{
  if(z>10){
    return 10;
  }else{
    return z;
  }
}

void a(){
  transform(11);
}
void b(int z){
  transform(z);
}

int main()
{
  int z=5;
  b(z);
  a();
}
