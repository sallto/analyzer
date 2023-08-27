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
void b(){
  transform(5);
}

int main()
{
  int z;
  a();
  b();
  return z;
}
