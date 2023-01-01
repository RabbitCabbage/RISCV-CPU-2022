#include "io.h"

int N = 7;
int used[10], a[10];

void dfs(int pos) {
  if (pos == N + 1) {
    for (int i = 1; i <= N; ++i) {
      outl(a[i]);
      outb(' ');
    }
    outb('\n');
    return;
  }
  for (int i = 1; i <= N; ++i) {
    if (!used[i]) {
      used[i] = 1;
      a[pos] = i;
      dfs(pos + 1);
      used[i] = 0;
    }
  }
}

int main() { dfs(1); }
