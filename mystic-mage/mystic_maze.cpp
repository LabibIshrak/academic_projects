// Mystic Maze — GLFW+GLAD
// Start Menu + Settings/Help/About + Gameplay (minimap, ghost, 3:00 timer)
// Music is OPTIONAL: dynamically loads winmm.dll if present (no linker flags).
// No STL containers.

#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <cmath>
#include <cstring>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

// ---------- stb_image (PNG loader) ----------
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_NO_STDIO
#define STBI_MALLOC(sz)       std::malloc(sz)
#define STBI_REALLOC(p,nsz)   std::realloc(p,nsz)
#define STBI_FREE(p)          std::free(p)
#include "stb_image.h"

// ---------- Windows helpers (paths + optional dynamic audio) ----------
#if defined(_WIN32)
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
  #include <direct.h>
  #define PATH_SEP '\\'
  static void getExeDir(char* out, size_t outsz){
    char buf[MAX_PATH]={0};
    DWORD len = GetModuleFileNameA(NULL, buf, (DWORD)sizeof(buf));
    if(len==0 || len>=sizeof(buf)){ out[0]=0; return; }
    buf[len]=0;
    for(int i=(int)len-1;i>=0;--i) if(buf[i]=='\\'||buf[i]=='/'){ buf[i]=0; break; }
    std::snprintf(out,outsz,"%s",buf);
  }
  static void getCWD(char* out, size_t outsz){ if(_getcwd(out, (int)outsz)==NULL) out[0]=0; }

  // --- Dynamic winmm loader (no -lwinmm needed) ---
  #ifndef SND_ASYNC
  #define SND_ASYNC    0x0001
  #endif
  #ifndef SND_LOOP
  #define SND_LOOP     0x0008
  #endif
  #ifndef SND_FILENAME
  #define SND_FILENAME 0x00020000
  #endif
  typedef BOOL (WINAPI *PlaySoundAFn)(LPCSTR, HMODULE, DWORD);
  static HMODULE     g_winmm = NULL;
  static PlaySoundAFn g_PlaySoundA = NULL;
  static void initWinMM(){
    if(g_winmm) return;
    g_winmm = LoadLibraryA("winmm.dll");
    if(g_winmm) g_PlaySoundA = (PlaySoundAFn)GetProcAddress(g_winmm, "PlaySoundA");
  }
  static void shutdownWinMM(){
    if(g_winmm){ FreeLibrary(g_winmm); g_winmm=NULL; g_PlaySoundA=NULL; }
  }
#else
  #include <unistd.h>
  #include <limits.h>
  #define PATH_SEP '/'
  static void getExeDir(char* out, size_t outsz){
    char buf[PATH_MAX]={0};
    ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf)-1);
    if(n<=0){ out[0]=0; return; }
    buf[n]=0;
    for(ssize_t i=n-1;i>=0;--i) if(buf[i]=='/'){ buf[i]=0; break; }
    std::snprintf(out,outsz,"%s",buf);
  }
  static void getCWD(char* out, size_t outsz){ if(getcwd(out,outsz)==NULL) out[0]=0; }
  static void initWinMM(){}
  static void shutdownWinMM(){}
#endif

static void joinPath(char* out, size_t outsz, const char* dir, const char* leaf){
  size_t ld = std::strlen(dir);
  if(ld==0){ std::snprintf(out,outsz,"%s",leaf); return; }
  char sep = PATH_SEP;
  bool needSep = !(dir[ld-1]==sep || dir[ld-1]=='/' || dir[ld-1]=='\\');
  if(needSep) std::snprintf(out,outsz,"%s%c%s",dir,sep,leaf);
  else        std::snprintf(out,outsz,"%s%s",dir,leaf);
}

// ---------------- Config ----------------
static const int   WIN_W_INIT = 1280;
static const int   WIN_H_INIT = 720;
static const float FOV_DEG    = 80.0f;

static const int   MAZE_W = 31;          // must be odd
static const int   MAZE_H = 31;          // must be odd
static const float WALL_H = 1.6f;

static const float MOVE_SPEED    = 2.2f;
static const float SPRINT_MULT   = 1.8f;
static const float TURN_SENS     = 0.12f;
static const float COLLIDE_R     = 0.14f;
static const float STAMINA_MAX   = 4.0f;
static const float STAMINA_REGEN = 0.8f;

static const float SKY[3]   = {0.08f, 0.10f, 0.16f};
static const float FLOORC[3]= {0.10f, 0.12f, 0.10f};
static const float WALLC[3] = {0.75f, 0.75f, 0.78f};

enum Cell : unsigned char { CELL_WALL=1, CELL_PATH=0, CELL_GOAL=2, CELL_KEY=3 };
static const int REQUIRE_KEY = 0;

// Maze flavor
static const int ALCOVE_PROB = 12;
static const int SPUR_TRIES  = 120;
static const int SPUR_MAXLEN = 6;
static const int BRAID_PROB  = 18;

// Ghost tuning
static const float GHOST_SPEED   = 1.9f;
static const float GHOST_RADIUS  = 0.16f;
static const float GHOST_HEIGHT  = 2.0f;
static const float GHOST_REPATH  = 0.20f;
static const int   NO_CAMP_RADIUS= 2;

// Timer — 3 minutes
static const float START_TIME = 180.0f;

// About / meta
static const char* VERSION_NAME = "v1.0";
static const char* DEV_NAME     = "Your Name";

// ---------------- Globals ----------------
static unsigned char grid[MAZE_H][MAZE_W];
static bool visited[MAZE_H][MAZE_W];
static int  startX=1, startY=1, goalX=MAZE_W-2, goalY=MAZE_H-2;

struct Player { float x,y; float yaw; float stamina; } player;
static bool paused=false, showMap=true, won=false, lost=false, timeup=false, hasKey=false;
static bool keyDown[512]={false};

static int SCR_W = WIN_W_INIT, SCR_H = WIN_H_INIT;

static float* zbuf = nullptr;
static int    zcap = 0;

static double lastTime=0.0;
static float  dt=0.0f, fps=0.0f;

static float timeLeft = START_TIME;

// Ghost state
struct Ghost { float x,y, tx,ty; bool hasTarget; float aspect; } ghost;
static GLuint ghostTex = 0;

// -------------- Menu state machine --------------
enum Screen { SCR_MENU=0, SCR_PLAY=1, SCR_SETTINGS=2, SCR_HELP=3, SCR_ABOUT=4 };
static Screen screen = SCR_MENU;
static int    menuIndex = 0;    // 0..4
static int    settingsIndex = 0;// 0..1
static bool   musicOn   = true;

// ---------------- RNG / helpers ----------------
static inline int   irand(int a,int b){ return a + (std::rand()%(b-a+1)); }
static inline float clampf(float x,float lo,float hi){ return x<lo?lo:(x>hi?hi:x); }
static void shuffle4(int a[4]){ for(int i=3;i>0;--i){ int j=std::rand()%(i+1); int t=a[i]; a[i]=a[j]; a[j]=t; } }
static inline bool inBounds(int x,int y){ return x>=0 && y>=0 && x<MAZE_W && y<MAZE_H; }
static int openNeighbors(int x,int y){
  int c=0;
  if(inBounds(x+1,y) && grid[y][x+1]!=CELL_WALL) ++c;
  if(inBounds(x-1,y) && grid[y][x-1]!=CELL_WALL) ++c;
  if(inBounds(x,y+1) && grid[y+1][x]!=CELL_WALL) ++c;
  if(inBounds(x,y-1) && grid[y-1][x]!=CELL_WALL) ++c;
  return c;
}

// ---------------- Maze generation ----------------
static void carve(int cx,int cy){
  int d[4]={0,1,2,3}; shuffle4(d);
  for(int i=0;i<4;++i){
    int nx=cx, ny=cy, mx=cx, my=cy;
    if(d[i]==0){ ny=cy-2; my=cy-1; }
    if(d[i]==1){ nx=cx+2; mx=cx+1; }
    if(d[i]==2){ ny=cy+2; my=cy+1; }
    if(d[i]==3){ nx=cx-2; mx=cx-1; }
    if(nx<=0||ny<=0||nx>=MAZE_W-1||ny>=MAZE_H-1) continue;
    if(grid[ny][nx]==CELL_WALL){ grid[my][mx]=CELL_PATH; grid[ny][nx]=CELL_PATH; carve(nx,ny); }
  }
}
static void addAlcoves(){
  if (ALCOVE_PROB <= 0) return;
  for(int y=1; y<MAZE_H-1; ++y){
    for(int x=1; x<MAZE_W-1; ++x){
      if(grid[y][x]==CELL_WALL){
        if(openNeighbors(x,y)==1 && (std::rand()%100)<ALCOVE_PROB){
          if(!(std::abs(x-startX)<=1 && std::abs(y-startY)<=1)) grid[y][x]=CELL_PATH;
        }
      }
    }
  }
}
static void addDeadEndSpurs(){
  const int dx4[4]={1,-1,0,0};
  const int dy4[4]={0,0,1,-1};
  for(int t=0;t<SPUR_TRIES;++t){
    int sx = irand(1,MAZE_W-2), sy = irand(1,MAZE_H-2);
    if(grid[sy][sx]!=CELL_PATH) continue;
    if(sx==startX && sy==startY) continue;
    if(sx==goalX  && sy==goalY ) continue;

    int dirs[4]={0,1,2,3}; shuffle4(dirs);
    int dir=-1;
    for(int k=0;k<4;++k){
      int nx = sx + dx4[dirs[k]], ny = sy + dy4[dirs[k]];
      if(!inBounds(nx,ny)) continue;
      if(grid[ny][nx]==CELL_WALL){ dir = dirs[k]; break; }
    }
    if(dir==-1) continue;

    int len = irand(2, SPUR_MAXLEN);
    int x = sx, y = sy; bool ok=true;
    for(int step=0; step<len; ++step){
      x += dx4[dir]; y += dy4[dir];
      if(!inBounds(x,y)){ ok=false; break; }
      if(grid[y][x]!=CELL_WALL){ ok=false; break; }
      grid[y][x]=CELL_PATH;
      if(openNeighbors(x,y)>1){ grid[y][x]=CELL_WALL; ok=false; break; }
    }
    if(!ok){
      int rx=x, ry=y;
      for(int step=0; step<len; ++step){
        if(!inBounds(rx,ry)) break;
        if(grid[ry][rx]==CELL_WALL) break;
        if(rx==sx && ry==sy) break;
        grid[ry][rx]=CELL_WALL;
        rx -= dx4[dir]; ry -= dy4[dir];
      }
    }
  }
}
static void addBraids(){
  if(BRAID_PROB<=0) return;
  for(int y=1; y<MAZE_H-1; ++y){
    for(int x=1; x<MAZE_W-1; ++x){
      if(grid[y][x]!=CELL_WALL) continue;
      bool horiz = ( (x&1)==1 && (y&1)==0 );
      bool vert  = ( (x&1)==0 && (y&1)==1 );
      if(horiz){
        int lx=x-1, rx=x+1;
        if(inBounds(lx,y) && inBounds(rx,y) && grid[y][lx]==CELL_PATH && grid[y][rx]==CELL_PATH){
          if((std::rand()%100) < BRAID_PROB) grid[y][x]=CELL_PATH;
        }
      } else if(vert){
        int uy=y-1, dy=y+1;
        if(inBounds(x,uy) && inBounds(x,dy) && grid[uy][x]==CELL_PATH && grid[dy][x]==CELL_PATH){
          if((std::rand()%100) < BRAID_PROB) grid[y][x]=CELL_PATH;
        }
      }
    }
  }
}
static void bfsDistances(int sx,int sy, int dist[MAZE_H][MAZE_W]){
  static int qx[MAZE_W*MAZE_H], qy[MAZE_W*MAZE_H];
  for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x) dist[y][x]=-1;
  int head=0, tail=0;
  if(!inBounds(sx,sy)) return;
  dist[sy][sx]=0; qx[tail]=sx; qy[tail]=sy; ++tail;
  const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
  while(head<tail){
    int x=qx[head], y=qy[head]; ++head;
    for(int k=0;k<4;++k){
      int nx=x+dx[k], ny=y+dy[k];
      if(!inBounds(nx,ny)) continue;
      unsigned char c = grid[ny][nx];
      if(!(c==CELL_PATH || c==CELL_GOAL || c==CELL_KEY)) continue;
      if(dist[ny][nx]!=-1) continue;
      dist[ny][nx]=dist[y][x]+1; qx[tail]=nx; qy[tail]=ny; ++tail;
    }
  }
}
static void chooseFarthestGoal(){
  static int dist[MAZE_H][MAZE_W];
  bfsDistances(startX,startY,dist);
  int bestD=-1, bx=startX, by=startY;
  for(int y=1;y<MAZE_H-1;++y){
    for(int x=1;x<MAZE_W-1;++x){
      if(grid[y][x]==CELL_PATH && dist[y][x]>bestD){ bestD=dist[y][x]; bx=x; by=y; }
    }
  }
  goalX=bx; goalY=by; grid[goalY][goalX]=CELL_GOAL;
}
static void spawnGhostFar(){
  static int dist[MAZE_H][MAZE_W];
  bfsDistances(startX,startY,dist);
  int maxD=0; for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x) if(dist[y][x]>maxD) maxD=dist[y][x];
  int threshold = (int)(maxD*0.6f);
  for(int tries=0; tries<1000; ++tries){
    int gx = irand(1,MAZE_W-2), gy = irand(1,MAZE_H-2);
    if(grid[gy][gx]==CELL_PATH && dist[gy][gx]>=threshold && !(gx==goalX&&gy==goalY)){
      ghost.x = gx + 0.5f; ghost.y = gy + 0.5f;
      ghost.tx=ghost.x; ghost.ty=ghost.y; ghost.hasTarget=false; return;
    }
  }
  ghost.x = goalX + 0.5f; ghost.y = goalY + 0.5f; ghost.tx=ghost.x; ghost.ty=ghost.y; ghost.hasTarget=false;
}
static void generateMaze(){
  for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x){ grid[y][x]=CELL_WALL; visited[y][x]=false; }
  grid[1][1]=CELL_PATH;
  carve(1,1);
  addDeadEndSpurs();
  addAlcoves();
  addBraids();
  chooseFarthestGoal();
  hasKey=false;
  spawnGhostFar();
}
static void computeShortestPathMask(int sx,int sy, bool mask[MAZE_H][MAZE_W], int distGoal[MAZE_H][MAZE_W]){
  for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x) mask[y][x]=false;
  if(!inBounds(sx,sy) || distGoal[sy][sx]<0) return;
  int x=sx, y=sy; mask[y][x]=true;
  const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
  for(int steps=0; steps<MAZE_W*MAZE_H; ++steps){
    if(x==goalX && y==goalY) break;
    int bestX=x, bestY=y, best=distGoal[y][x];
    for(int k=0;k<4;++k){
      int nx=x+dx[k], ny=y+dy[k];
      if(!inBounds(nx,ny)) continue;
      unsigned char c = grid[ny][nx];
      if(!(c==CELL_PATH || c==CELL_GOAL || c==CELL_KEY)) continue;
      int d = distGoal[ny][nx];
      if(d>=0 && d<best){ best=d; bestX=nx; bestY=ny; }
    }
    if(bestX==x && bestY==y) break;
    x=bestX; y=bestY; mask[y][x]=true;
  }
}

// ---------------- Renderer core ----------------
struct Vertex { float x,y,r,g,b,u,v,t; };
static const int MAX_VERTS = 700000;
static Vertex *verts=nullptr; static int vertCount=0;

static GLuint vao=0, vbo=0, prog=0;
static GLint  uModeLoc=-1, uScreenLoc=-1, uTexLoc=-1;

static const char* vsSrc =
"#version 330 core\n"
"layout(location=0) in vec2 inPos;\n"
"layout(location=1) in vec3 inCol;\n"
"layout(location=2) in vec2 inUV;\n"
"layout(location=3) in float inTex;\n"
"uniform int uMode; // 0: NDC, 1: pixel\n"
"uniform vec2 uScreen;\n"
"out vec3 vCol; out vec2 vUV; out float vTex;\n"
"void main(){\n"
"  vec2 p=inPos; if(uMode==1){ p=vec2((p.x/uScreen.x)*2.0-1.0, 1.0-(p.y/uScreen.y)*2.0);} \n"
"  gl_Position=vec4(p,0.0,1.0); vCol=inCol; vUV=inUV; vTex=inTex; }\n";

static const char* fsSrc =
"#version 330 core\n"
"in vec3 vCol; in vec2 vUV; in float vTex; out vec4 frag; uniform sampler2D uTex;\n"
"void main(){ if(vTex>0.5){ vec4 s=texture(uTex,vUV); if(s.a<0.05) discard; frag=s; } else { frag=vec4(vCol,1.0);} }\n";

static GLuint compile(GLenum type, const char* src){
  GLuint s=glCreateShader(type); glShaderSource(s,1,&src,nullptr); glCompileShader(s);
  GLint ok=0; glGetShaderiv(s,GL_COMPILE_STATUS,&ok);
  if(!ok){ char log[1024]; glGetShaderInfoLog(s,1024,nullptr,log); std::fprintf(stderr,"Shader err:\n%s\n",log); std::exit(1); }
  return s;
}
static GLuint link(GLuint vs, GLuint fs){
  GLuint p=glCreateProgram(); glAttachShader(p,vs); glAttachShader(p,fs); glLinkProgram(p);
  GLint ok=0; glGetProgramiv(p,GL_LINK_STATUS,&ok);
  if(!ok){ char log[1024]; glGetProgramInfoLog(p,1024,nullptr,log); std::fprintf(stderr,"Link err:\n%s\n",log); std::exit(1); }
  return p;
}
static inline void pushTri(float x0,float y0,float r0,float g0,float b0,float u0,float v0,float t0,
                           float x1,float y1,float r1,float g1,float b1,float u1,float v1,float t1,
                           float x2,float y2,float r2,float g2,float b2,float u2,float v2,float t2){
  if(vertCount+3>=MAX_VERTS) return;
  verts[vertCount++]={x0,y0,r0,g0,b0,u0,v0,t0};
  verts[vertCount++]={x1,y1,r1,g1,b1,u1,v1,t1};
  verts[vertCount++]={x2,y2,r2,g2,b2,u2,v2,t2};
}
static inline void pushQuadNDC(float x0,float y0,float x1,float y1, float r,float g,float b){
  pushTri(x0,y0,r,g,b,0,0,0, x1,y0,r,g,b,0,0,0, x1,y1,r,g,b,0,0,0);
  pushTri(x0,y0,r,g,b,0,0,0, x1,y1,r,g,b,0,0,0, x0,y1,r,g,b,0,0,0);
}
static inline void pushQuadPx(float x0,float y0,float x1,float y1, float r,float g,float b){
  pushQuadNDC(x0,y0,x1,y1,r,g,b);
}
static inline void pushQuadPxTex(float x0,float y0,float x1,float y1, float u0,float v0,float u1,float v1){
  pushTri(x0,y0,1,1,1,u0,v0,1,  x1,y0,1,1,1,u1,v0,1,  x1,y1,1,1,1,u1,v1,1);
  pushTri(x0,y0,1,1,1,u0,v0,1,  x1,y1,1,1,1,u1,v1,1,  x0,y1,1,1,1,u0,v1,1);
}

// ------------- Tiny 3x5 font (digits + ':' + uppercase) -------------
static const unsigned char DIGITS[11][5] = {
  {0b111,0b101,0b101,0b101,0b111}, // 0
  {0b010,0b110,0b010,0b010,0b111}, // 1
  {0b111,0b001,0b111,0b100,0b111}, // 2
  {0b111,0b001,0b111,0b001,0b111}, // 3
  {0b101,0b101,0b111,0b001,0b001}, // 4
  {0b111,0b100,0b111,0b001,0b111}, // 5
  {0b111,0b100,0b111,0b101,0b111}, // 6
  {0b111,0b001,0b001,0b001,0b001}, // 7
  {0b111,0b101,0b111,0b101,0b111}, // 8
  {0b111,0b101,0b111,0b001,0b111}, // 9
  {0b000,0b010,0b000,0b010,0b000}  // :
};
// 3x5 uppercase A-Z + space
static const unsigned char LETTERS[27][5] = {
  {0b111,0b101,0b111,0b101,0b101}, // A
  {0b110,0b101,0b110,0b101,0b110}, // B
  {0b111,0b100,0b100,0b100,0b111}, // C
  {0b110,0b101,0b101,0b101,0b110}, // D
  {0b111,0b100,0b110,0b100,0b111}, // E
  {0b111,0b100,0b110,0b100,0b100}, // F
  {0b111,0b100,0b101,0b101,0b111}, // G
  {0b101,0b101,0b111,0b101,0b101}, // H
  {0b111,0b010,0b010,0b010,0b111}, // I
  {0b111,0b001,0b001,0b101,0b111}, // J
  {0b101,0b110,0b100,0b110,0b101}, // K
  {0b100,0b100,0b100,0b100,0b111}, // L
  {0b101,0b111,0b111,0b101,0b101}, // M
  {0b101,0b111,0b111,0b111,0b101}, // N
  {0b111,0b101,0b101,0b101,0b111}, // O
  {0b111,0b101,0b111,0b100,0b100}, // P
  {0b111,0b101,0b101,0b111,0b001}, // Q
  {0b111,0b101,0b111,0b110,0b101}, // R
  {0b111,0b100,0b111,0b001,0b111}, // S
  {0b111,0b010,0b010,0b010,0b010}, // T
  {0b101,0b101,0b101,0b101,0b111}, // U
  {0b101,0b101,0b101,0b101,0b010}, // V
  {0b101,0b101,0b111,0b111,0b101}, // W
  {0b101,0b101,0b010,0b101,0b101}, // X
  {0b101,0b101,0b010,0b010,0b010}, // Y
  {0b111,0b001,0b010,0b100,0b111}, // Z
  {0b000,0b000,0b000,0b000,0b000}, // space
};
static void drawGlyphPx(float x, float y, float s, int idx, float r,float g,float b){
  if(idx<0||idx>10) return;
  for(int row=0; row<5; ++row){
    unsigned char bits = DIGITS[idx][row];
    for(int col=0; col<3; ++col){
      if(bits & (1<<(2-col))){
        float x0 = x + col*s, y0 = y + row*s;
        pushQuadPx(x0,y0, x0+s-1, y0+s-1, r,g,b);
      }
    }
  }
}
static void drawLetterPx(float x, float y, float s, char ch, float r,float g,float b){
  int idx;
  if(ch==' ') idx=26;
  else { idx = (int)(ch - 'A'); if(idx<0||idx>25) return; }
  for(int row=0; row<5; ++row){
    unsigned char bits = LETTERS[idx][row];
    for(int col=0; col<3; ++col){
      if(bits & (1<<(2-col))){
        float x0 = x + col*s, y0 = y + row*s;
        pushQuadPx(x0,y0, x0+s-1, y0+s-1, r,g,b);
      }
    }
  }
}
static float measureStringPx(const char* text, float s){
  float w=0; for(size_t i=0; text[i]; ++i){
    char ch=text[i];
    if(ch>='a'&&ch<='z') ch = (char)(ch-'a'+'A');
    if((ch>='0'&&ch<='9')||ch==':'|| (ch>='A'&&ch<='Z') || ch==' ')
      w += 3*s + s;
  }
  if(w>0) w -= s;
  return w;
}
static void drawStringPx(float x, float y, float s, const char* text, float r,float g,float b){
  float pen=x;
  for(size_t i=0; text[i]; ++i){
    char ch=text[i];
    if(ch>='a'&&ch<='z') ch = (char)(ch-'a'+'A');
    if(ch>='0'&&ch<='9'){
      int idx = (int)(ch-'0'); drawGlyphPx(pen,y,s,idx,r,g,b); pen += 3*s + s;
    } else if(ch==':'){
      drawGlyphPx(pen,y,s,10,r,g,b); pen += 3*s + s;
    } else if((ch>='A'&&ch<='Z') || ch==' '){
      drawLetterPx(pen,y,s,ch,r,g,b); pen += 3*s + s;
    } else pen += s;
  }
}
static void drawStringCentered(float cy, float s, const char* text, float r,float g,float b){
  float w = measureStringPx(text, s);
  float x = (SCR_W - w)*0.5f;
  drawStringPx(x, cy, s, text, r,g,b);
}

// ---------------- Movement / Logic ----------------
static inline bool isSolidCell(int gx,int gy){ return !inBounds(gx,gy) || grid[gy][gx]==CELL_WALL; }
static void resolveCollisions(float& x,float& y){
  for(int iy=(int)std::floor(y-1); iy<=(int)std::floor(y+1); ++iy){
    for(int ix=(int)std::floor(x-1); ix<=(int)std::floor(x+1); ++ix){
      if(isSolidCell(ix,iy)) {
        float bx=(float)ix, by=(float)iy, bx2=bx+1.0f, by2=by+1.0f;
        float cx = (x<bx)?bx: (x>bx2?bx2:x);
        float cy = (y<by)?by: (y>by2?by2:y);
        float dx = x - cx, dy = y - cy;
        float d2 = dx*dx + dy*dy, R2 = COLLIDE_R*COLLIDE_R;
        if(d2 < R2){
          if(d2 < 1e-12f){ x += 0.001f; y += 0.001f; continue; }
          float d = std::sqrt(d2);
          float push = (COLLIDE_R - d);
          x += (dx/d)*push; y += (dy/d)*push;
        }
      }
    }
  }
  if(x<0.001f) x=0.001f; if(y<0.001f) y=0.001f;
  if(x>MAZE_W-0.001f) x=MAZE_W-0.001f; if(y>MAZE_H-0.001f) y=MAZE_H-0.001f;
}
static inline void tryMove(float vx,float vy){ float nx = player.x + vx, ny = player.y + vy; resolveCollisions(nx, ny); player.x = nx; player.y = ny; }
static void resetGame(){
  generateMaze();
  player.x=(float)startX+0.5f; player.y=(float)startY+0.5f; player.yaw=0.0f; player.stamina=STAMINA_MAX;
  won=false; lost=false; timeup=false; hasKey=false; paused=false;
  timeLeft = START_TIME;
  for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x) visited[y][x]=false;
}

// ---- Ghost anti-blocking ----
static float ghostRepathAcc = 0.0f;
static void updateGhostPath(){
  static int distToPlayer[MAZE_H][MAZE_W];
  static int distToGoal  [MAZE_H][MAZE_W];
  static bool pathMask[MAZE_H][MAZE_W];

  int pGX=(int)std::floor(player.x), pGY=(int)std::floor(player.y);
  bfsDistances(pGX,pGY,distToPlayer);
  bfsDistances(goalX,goalY,distToGoal);
  computeShortestPathMask(pGX,pGY, pathMask, distToGoal);

  int gX=(int)std::floor(ghost.x), gY=(int)std::floor(ghost.y);
  if(!inBounds(gX,gY) || distToPlayer[gY][gX]<0){ ghost.hasTarget=false; return; }

  int bestX=gX, bestY=gY, bestD=distToPlayer[gY][gX];
  const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
  bool found=false;

  for(int k=0;k<4;++k){
    int nx=gX+dx[k], ny=gY+dy[k];
    if(!inBounds(nx,ny)) continue;
    unsigned char c = grid[ny][nx];
    if(!(c==CELL_PATH || c==CELL_GOAL || c==CELL_KEY)) continue;
    int dp = distToPlayer[ny][nx];
    if(dp<0 || dp>=bestD) continue;

    int dgGhost = distToGoal[ny][nx];
    int dgPlayer= (inBounds(pGX,pGY)? distToGoal[pGY][pGX] : -1);
    bool nearExit = (dgGhost>=0 && dgGhost<=NO_CAMP_RADIUS);
    bool playerNearExit = (dgPlayer>=0 && dgPlayer<=NO_CAMP_RADIUS);
    if(nearExit && !playerNearExit) continue;

    bool onPath = pathMask[ny][nx];
    if(onPath && dgGhost>=0 && dgPlayer>=0 && dgGhost < dgPlayer) continue;

    bestD = dp; bestX = nx; bestY = ny; found=true;
  }
  if(!found){
    for(int k=0;k<4;++k){
      int nx=gX+dx[k], ny=gY+dy[k];
      if(!inBounds(nx,ny)) continue;
      unsigned char c = grid[ny][nx];
      if(!(c==CELL_PATH || c==CELL_GOAL || c==CELL_KEY)) continue;
      int dp = distToPlayer[ny][nx];
      if(dp>=0 && dp<bestD){ bestD = dp; bestX = nx; bestY = ny; found=true; }
    }
  }
  ghost.tx = bestX + 0.5f; ghost.ty = bestY + 0.5f; ghost.hasTarget=true;
}
static void updateLogic(GLFWwindow* win){
  if(paused) return;
  double now=glfwGetTime();
  dt=(float)(now-lastTime); if(dt<0) dt=0; if(dt>0.25f) dt=0.25f; lastTime=now;
  static double acc=0; static int frames=0; acc+=dt; frames++; if(acc>0.5){ fps=(float)(frames/acc); frames=0; acc=0; }

  // timer
  if(!won && !lost && !timeup){
    timeLeft -= dt;
    if(timeLeft <= 0.0f){ timeLeft=0.0f; timeup=true; paused=true; glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL); }
  }

  int pgx=(int)std::floor(player.x), pgy=(int)std::floor(player.y);
  if(pgx>=0&&pgy>=0&&pgx<MAZE_W&&pgy<MAZE_H) visited[pgy][pgx]=true;

  float rad = player.yaw * (3.1415926535f/180.0f);
  float dirX=std::sin(rad), dirY=-std::cos(rad);
  float rightX=std::cos(rad), rightY=std::sin(rad);

  float speed=MOVE_SPEED;
  bool sprint= keyDown[GLFW_KEY_LEFT_SHIFT] || keyDown[GLFW_KEY_RIGHT_SHIFT];
  if(sprint && player.stamina>0.15f){ speed*=SPRINT_MULT; player.stamina-=dt; if(player.stamina<0) player.stamina=0; }
  else { player.stamina += STAMINA_REGEN*dt; if(player.stamina>STAMINA_MAX) player.stamina=STAMINA_MAX; }

  if(keyDown[GLFW_KEY_W]) tryMove(dirX*speed*dt, dirY*speed*dt);
  if(keyDown[GLFW_KEY_S]) tryMove(-dirX*speed*dt, -dirY*speed*dt);
  if(keyDown[GLFW_KEY_A]) tryMove(-rightX*speed*dt, -rightY*speed*dt);
  if(keyDown[GLFW_KEY_D]) tryMove(rightX*speed*dt, rightY*speed*dt);

  unsigned char cell = grid[pgy][pgx];
  if (REQUIRE_KEY && cell==CELL_KEY){ hasKey=true; grid[pgy][pgx]=CELL_PATH; }
  if(cell==CELL_GOAL && (!REQUIRE_KEY || hasKey) && !timeup){ won=true; paused=true; glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL); }

  ghostRepathAcc += dt;
  if(!ghost.hasTarget || ghostRepathAcc >= GHOST_REPATH){ updateGhostPath(); ghostRepathAcc = 0.0f; }
  if(ghost.hasTarget){
    float vx = ghost.tx - ghost.x, vy = ghost.ty - ghost.y;
    float len = std::sqrt(vx*vx+vy*vy);
    if(len > 1e-4f){
      float step = GHOST_SPEED * dt;
      if(step >= len){ ghost.x = ghost.tx; ghost.y = ghost.ty; ghost.hasTarget=false; }
      else { ghost.x += vx/len*step; ghost.y += vy/len*step; }
    } else ghost.hasTarget=false;
  }

  float dx = player.x - ghost.x, dy = player.y - ghost.y;
  float d2 = dx*dx + dy*dy; float rsum = COLLIDE_R + GHOST_RADIUS;
  if(!won && !timeup && d2 < rsum*rsum){
    lost = true; paused = true; glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
  }
}

// ---------------- Game render (walls + sprite + HUD) ----------------
struct BuildCounts { int ndcCount; int totalCount; };

static BuildCounts buildFrameVerts(){
  vertCount=0;

  // background halves
  pushQuadNDC(-1,-1, 1,0, FLOORC[0],FLOORC[1],FLOORC[2]);
  pushQuadNDC(-1, 0, 1,1, SKY[0],  SKY[1],  SKY[2]);

  const float halfFov   = (FOV_DEG * 0.5f) * 3.1415926535f/180.0f;
  const float projPlane = (SCR_W*0.5f) / std::tan(halfFov);

  float viewRad = player.yaw * 3.1415926535f/180.0f;
  float fwdX=std::sin(viewRad), fwdY=-std::cos(viewRad);
  float rightX=std::cos(viewRad), rightY=std::sin(viewRad);

  if(SCR_W > zcap){ zbuf = (float*)std::realloc(zbuf, sizeof(float)*SCR_W); zcap=SCR_W; }

  for(int i=0;i<SCR_W;++i){
    float a = viewRad + ( ( (i + 0.5f) / (float)SCR_W ) - 0.5f ) * (2.0f * halfFov);
    float rayX=std::sin(a), rayY=-std::cos(a);

    int mapX=(int)std::floor(player.x), mapY=(int)std::floor(player.y);
    float sideDistX, sideDistY;
    float deltaDistX = (rayX==0)?1e30f:std::fabs(1.0f/rayX);
    float deltaDistY = (rayY==0)?1e30f:std::fabs(1.0f/rayY);
    int stepX=(rayX<0)?-1:1, stepY=(rayY<0)?-1:1;
    if(rayX<0) sideDistX=(player.x-mapX)*deltaDistX; else sideDistX=(mapX+1.0f-player.x)*deltaDistX;
    if(rayY<0) sideDistY=(player.y-mapY)*deltaDistY; else sideDistY=(mapY+1.0f-player.y)*deltaDistY;

    int hit=0, side=0; unsigned char hitCell=CELL_WALL;
    for(int steps=0; steps<2048; ++steps){
      if(sideDistX < sideDistY){ sideDistX += deltaDistX; mapX += stepX; side=0; }
      else {                     sideDistY += deltaDistY; mapY += stepY; side=1; }
      if(mapX<0||mapY<0||mapX>=MAZE_W||mapY>=MAZE_H){ hit=1; hitCell=CELL_WALL; break; }
      if(grid[mapY][mapX] != CELL_PATH){ hit=1; hitCell=grid[mapY][mapX]; break; }
    }
    if(!hit){ zbuf[i]=1e9f; continue; }

    float perpDist = side==0 ? (sideDistX - deltaDistX) : (sideDistY - deltaDistY);
    if(perpDist < 0.001f) perpDist = 0.001f;
    zbuf[i] = perpDist;

    float lineH   = (WALL_H * projPlane) / perpDist;
    float yTopPx  = (SCR_H*0.5f) - lineH*0.5f;
    float yBotPx  = yTopPx + lineH;
    if(yTopPx < 0) yTopPx = 0;
    if(yBotPx > SCR_H) yBotPx = (float)SCR_H;

    float x0 = -1.0f + (2.0f * i) / SCR_W;
    float x1 = -1.0f + (2.0f * (i+1)) / SCR_W;
    float y0 = 1.0f - 2.0f*(yTopPx / SCR_H);
    float y1 = 1.0f - 2.0f*(yBotPx / SCR_H);

    float sideMul = (side==1)?0.75f:1.0f;
    float fog     = std::exp(-0.055f * perpDist);
    float r=WALLC[0]*sideMul*0.8f, g=WALLC[1]*sideMul*0.8f, b=WALLC[2]*sideMul*0.8f;
    r = r*fog + SKY[0]*(1.0f-fog); g = g*fog + SKY[1]*(1.0f-fog); b = b*fog + SKY[2]*(1.0f-fog);
    if(hitCell==CELL_GOAL){ r=0.20f; g=0.95f; b=0.20f; }

    pushQuadNDC(x0,y1, x1,y0, r,g,b);
  }

  int ndcCount = vertCount;

  // Ghost sprite
  {
    float relX = ghost.x - player.x, relY = ghost.y - player.y;
    float sprRight   =  relX*rightX + relY*rightY;
    float sprForward =  relX*fwdX   + relY*fwdY;
    if(sprForward > 0.05f){
      float hPx = (GHOST_HEIGHT * ((SCR_W*0.5f)/std::tan((FOV_DEG*0.5f)*3.1415926535f/180.0f))) / sprForward;
      float aspect = (ghostTex ? ghost.aspect : 0.7f);
      float wPx = hPx * aspect;

      float centerX = (SCR_W*0.5f) + (sprRight * ((SCR_W*0.5f)/std::tan((FOV_DEG*0.5f)*3.1415926535f/180.0f)) / sprForward);
      float xL = centerX - wPx*0.5f, xR = centerX + wPx*0.5f;
      float yTopPx = (SCR_H*0.5f) - hPx*0.5f, yBotPx = yTopPx + hPx;
      if(yTopPx < 0) yTopPx = 0; if(yBotPx > SCR_H) yBotPx = (float)SCR_H;

      int cL = (int)std::floor(xL); if(cL<0) cL=0;
      int cR = (int)std::ceil (xR); if(cR>SCR_W) cR=SCR_W;

      for(int c=cL; c<cR; ++c){
        if(sprForward < zbuf[c] - 0.0001f){
          if(ghostTex){
            float u = (c - xL) / (xR - xL);
            pushQuadPxTex((float)c, yTopPx, (float)(c+1), yBotPx, u, 0.0f, u, 1.0f);
          }else{
            pushQuadPx((float)c, yTopPx, (float)(c+1), yBotPx, 0.9f, 0.1f, 0.1f);
          }
        }
      }
    }
  }

  // HUD: minimap, stamina, timer
  const float s=5.0f, m=8.0f;
  if(showMap){
    float mmX = SCR_W - m - MAZE_W*s, mmY = m;
    pushQuadPx(mmX-2, mmY-2, mmX + MAZE_W*s + 2, mmY + MAZE_H*s + 2, 0.05f,0.05f,0.07f);
    for(int y=0;y<MAZE_H;++y) for(int x=0;x<MAZE_W;++x){
      float rx=mmX + x*s, ry=mmY + y*s;
      unsigned char c=grid[y][x];
      float r,g,b;
      if(c==CELL_WALL){ r=0.85f; g=0.85f; b=0.90f; }
      else { if(visited[y][x]) { r=0.18f; g=0.22f; b=0.26f; } else { r=0.10f; g=0.12f; b=0.14f; } }
      pushQuadPx(rx,ry, rx+s,ry+s, r,g,b);
      if(c==CELL_GOAL) pushQuadPx(rx+1,ry+1, rx+s-1,ry+s-1, 0.1f,0.95f,0.1f);
    }
    float px = mmX + player.x*s, py = mmY + player.y*s; pushQuadPx(px-2,py-2, px+2,py+2, 0.20f,0.92f,0.98f);
    float gx = mmX + ghost.x*s,  gy = mmY + ghost.y*s;  pushQuadPx(gx-2,gy-2, gx+2,gy+2, 0.98f,0.55f,0.15f);
  }
  float pct = clampf(player.stamina/STAMINA_MAX, 0.0f, 1.0f);
  float bx=10, by=(float)SCR_H-24, bw=200, bh=10;
  pushQuadPx(bx,by, bx+bw,by+bh, 0.15f,0.15f,0.2f);
  pushQuadPx(bx,by, bx+bw*pct,by+bh, 0.3f,0.85f,0.4f);

  int t = (int)std::ceil(timeLeft); if(t<0) t=0;
  int MM = t/60, SS = t%60;
  float ds=12.0f, wDigit=3*ds, wColon=3*ds, sp=ds, colonPad=ds;
  float totalW = wDigit + sp + wDigit + colonPad + wColon + colonPad + sp + wDigit + sp + wDigit;
  float x0 = (SCR_W - totalW)*0.5f, y0 = 8.0f;
  int d0 = MM/10, d1 = MM%10, d2 = SS/10, d3 = SS%10;
  float x = x0;
  drawGlyphPx(x, y0, ds, d0, 0.95f,0.95f,0.95f); x += wDigit + sp;
  drawGlyphPx(x, y0, ds, d1, 0.95f,0.95f,0.95f); x += wDigit + colonPad;
  drawGlyphPx(x, y0, ds, 10,  0.95f,0.95f,0.95f); x += wColon + colonPad;
  drawGlyphPx(x, y0, ds, d2, 0.95f,0.95f,0.95f); x += wDigit + sp;
  drawGlyphPx(x, y0, ds, d3, 0.95f,0.95f,0.95f);

  if(won){   pushQuadPx(SCR_W*0.25f, SCR_H*0.42f, SCR_W*0.75f, SCR_H*0.58f, 0.0f,0.6f,0.0f); }
  if(lost){  pushQuadPx(SCR_W*0.25f, SCR_H*0.42f, SCR_W*0.75f, SCR_H*0.58f, 0.7f,0.0f,0.0f); }
  if(timeup){pushQuadPx(SCR_W*0.25f, SCR_H*0.42f, SCR_W*0.75f, SCR_H*0.58f, 0.9f,0.5f,0.0f); }

  int totalCount = vertCount;
  return { ndcCount, totalCount };
}
static void renderFrame(const BuildCounts& cts){
  glUseProgram(prog);
  glBindVertexArray(vao);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(Vertex)*vertCount, verts);

  glUniform1i(uModeLoc, 0);
  glDrawArrays(GL_TRIANGLES, 0, cts.ndcCount);

  glUniform1i(uModeLoc, 1);
  glUniform2f(uScreenLoc, (float)SCR_W, (float)SCR_H);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, ghostTex);
  glUniform1i(uTexLoc, 0);
  glDrawArrays(GL_TRIANGLES, cts.ndcCount, cts.totalCount - cts.ndcCount);

  glBindVertexArray(0);
  glUseProgram(0);
}

// ---------- UI-only render ----------
static void renderUIOnly(){
  glUseProgram(prog);
  glBindVertexArray(vao);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(Vertex)*vertCount, verts);
  glUniform1i(uModeLoc, 1);
  glUniform2f(uScreenLoc, (float)SCR_W, (float)SCR_H);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, 0);
  glUniform1i(uTexLoc, 0);
  glDrawArrays(GL_TRIANGLES, 0, vertCount);
  glBindVertexArray(0);
  glUseProgram(0);
}

// ---------------- Texture loading ----------------
static unsigned char* loadFileToMem(const char* path, int* outSize){
  FILE* f = std::fopen(path, "rb");
  if(!f) return nullptr;
  std::fseek(f, 0, SEEK_END); long sz = std::ftell(f); std::fseek(f, 0, SEEK_SET);
  if(sz<=0){ std::fclose(f); return nullptr; }
  unsigned char* data = (unsigned char*)std::malloc((size_t)sz);
  if(!data){ std::fclose(f); return nullptr; }
  size_t rd = std::fread(data, 1, (size_t)sz, f); std::fclose(f);
  if(rd != (size_t)sz){ std::free(data); return nullptr; }
  *outSize = (int)sz; return data;
}
static GLuint loadPNGTexture(const char* path, float* aspectOut){
  int fsize=0; unsigned char* fileData = loadFileToMem(path, &fsize);
  if(!fileData){ std::fprintf(stderr,"[ERR] open fail: %s\n", path); return 0; }

  int w=0,h=0,n=0; stbi_uc* pixels = stbi_load_from_memory(fileData, fsize, &w, &h, &n, 4);
  std::free(fileData);
  if(!pixels){ std::fprintf(stderr,"[ERR] decode fail: %s\n", path); return 0; }

  GLuint tex=0; glGenTextures(1,&tex); glBindTexture(GL_TEXTURE_2D, tex);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_2D, 0);
  stbi_image_free(pixels);

  if(aspectOut) *aspectOut = (float)w / (float)h;
  std::fprintf(stderr,"[OK] Loaded texture (%dx%d) from: %s\n", w,h,path);
  return tex;
}
static GLuint tryLoadGhostTexture(float* aspectOut){
  char exeDir[512]={0}, cwd[512]={0}, p[1024]={0};
  getExeDir(exeDir, sizeof(exeDir));
  getCWD(cwd, sizeof(cwd));
  std::fprintf(stderr,"[INFO] EXE dir: %s\n", exeDir[0]?exeDir:"<unknown>");
  std::fprintf(stderr,"[INFO] CWD    : %s\n", cwd[0]?cwd:"<unknown>");

  const char* names[] = { "maze_ghost.png", "assets/maze_ghost.png" };
  for(int i=0;i<2;++i){
    if(exeDir[0]){ joinPath(p,sizeof(p),exeDir,names[i]); GLuint t=loadPNGTexture(p, aspectOut); if(t){ std::fprintf(stderr,"[OK] Ghost tex @ EXE: %s\n", p); return t; } }
  }
  for(int i=0;i<2;++i){
    std::snprintf(p,sizeof(p), "%s", names[i]); GLuint t=loadPNGTexture(p, aspectOut); if(t){ std::fprintf(stderr,"[OK] Ghost tex @ CWD: %s\n", p); return t; }
  }
  if(exeDir[0]){
    char parent[512]={0}; std::snprintf(parent,sizeof(parent), "%s", exeDir);
    for(int i=(int)std::strlen(parent)-1;i>=0;--i){ if(parent[i]=='\\'||parent[i]=='/'){ parent[i]=0; break; } }
    for(int i=0;i<2;++i){ joinPath(p,sizeof(p),parent,names[i]); GLuint t=loadPNGTexture(p, aspectOut); if(t){ std::fprintf(stderr,"[OK] Ghost tex @ PARENT: %s\n", p); return t; } }
  }
  std::fprintf(stderr,"[WARN] Could not locate maze_ghost.png. Using fallback red sprite.\n");
  return 0;
}

// ---------------- Music wrappers (no linker flags needed) ----------------
static void musicPlayLoop(const char* path){
#if defined(_WIN32)
  if(!musicOn) return;
  if(!g_winmm) initWinMM();
  if(g_PlaySoundA) g_PlaySoundA(path, NULL, SND_FILENAME | SND_ASYNC | SND_LOOP);
#else
  (void)path;
#endif
}
static void musicStop(){
#if defined(_WIN32)
  if(!g_winmm) return;
  if(g_PlaySoundA) g_PlaySoundA(NULL, 0, 0);
#endif
}

// ---------------- Menus: drawing ----------------
static void drawMenuScreen(){
  vertCount=0;
  pushQuadPx(0,0, (float)SCR_W,(float)SCR_H, 0.06f,0.07f,0.10f);

  float ts = 18.0f;
  const char* title = "MYSTIC MAZE";
  float tw = measureStringPx(title, ts);
  float tx = (SCR_W - tw)*0.5f, ty = SCR_H*0.18f;
  drawStringPx(tx+3, ty+3, ts, title, 0.00f,0.00f,0.00f);
  drawStringPx(tx,   ty,   ts, title, 0.96f,0.86f,0.25f);

  const char* items[5] = { "PLAY GAME", "SETTINGS", "HELP", "ABOUT", "QUIT" };
  float itemS = 10.0f;
  float baseY = SCR_H*0.42f;
  for(int i=0;i<5;++i){
    float iw = measureStringPx(items[i], itemS);
    float ix = (SCR_W - iw)*0.5f;
    float iy = baseY + i*(itemS*6.0f);
    if(i==menuIndex){
      float pad = 12.0f;
      pushQuadPx(ix-pad, iy-8, ix+iw+pad, iy+itemS*5.0f+8, 0.15f,0.20f,0.35f);
      drawStringPx(ix, iy, itemS, items[i], 0.95f,0.95f,0.98f);
    }else{
      drawStringPx(ix, iy, itemS, items[i], 0.78f,0.82f,0.88f);
    }
  }
  drawStringCentered(SCR_H - 40.0f, 6.0f, "USE W/S OR UP/DOWN TO SELECT, ENTER TO CONFIRM", 0.70f,0.74f,0.82f);

  renderUIOnly();
}
static void drawSettingsScreen(){
  vertCount=0;
  pushQuadPx(0,0,(float)SCR_W,(float)SCR_H, 0.06f,0.07f,0.10f);
  drawStringCentered(SCR_H*0.14f, 14.0f, "SETTINGS", 0.96f,0.86f,0.25f);

  char musicLine[64];
  std::snprintf(musicLine,sizeof(musicLine),"MUSIC : %s", musicOn?"ON":"OFF");
  const char* items[2] = { musicLine, "BACK" };
  float itemS = 10.0f;
  float baseY = SCR_H*0.36f;
  for(int i=0;i<2;++i){
    float iw = measureStringPx(items[i], itemS);
    float ix = (SCR_W - iw)*0.5f;
    float iy = baseY + i*(itemS*6.0f);
    if(i==settingsIndex){
      float pad=12.0f;
      pushQuadPx(ix-pad, iy-8, ix+iw+pad, iy+itemS*5.0f+8, 0.15f,0.20f,0.35f);
      drawStringPx(ix, iy, itemS, items[i], 0.95f,0.95f,0.98f);
    }else{
      drawStringPx(ix, iy, itemS, items[i], 0.78f,0.82f,0.88f);
    }
  }
  drawStringCentered(SCR_H - 40.0f, 6.0f, "LEFT/RIGHT OR A/D TO TOGGLE. ESC/BACK TO MENU.", 0.70f,0.74f,0.82f);

  renderUIOnly();
}
static void drawHelpScreen(){
  vertCount=0;
  pushQuadPx(0,0,(float)SCR_W,(float)SCR_H, 0.06f,0.07f,0.10f);
  drawStringCentered(SCR_H*0.14f, 14.0f, "HELP", 0.96f,0.86f,0.25f);

  float s=8.0f; float y=SCR_H*0.30f;
  drawStringCentered(y,     s, "OBJECTIVE : REACH THE GREEN EXIT BEFORE TIME RUNS OUT", 0.90f,0.94f,0.98f);
  drawStringCentered(y+ s*7,s, "CONTROLS  : W A S D MOVE   MOUSE LOOK   SHIFT SPRINT", 0.90f,0.94f,0.98f);
  drawStringCentered(y+ s*14,s,"OTHER     : P PAUSE   M TOGGLE MINIMAP   R RESTART", 0.90f,0.94f,0.98f);
  drawStringCentered(y+ s*21,s,"GHOST     : CHASES YOU, WON'T CAMP THE EXIT", 0.90f,0.94f,0.98f);
  drawStringCentered(SCR_H - 40.0f, 6.0f, "PRESS ESC OR ENTER TO RETURN", 0.70f,0.74f,0.82f);

  renderUIOnly();
}
static void drawAboutScreen(){
  vertCount=0;
  pushQuadPx(0,0,(float)SCR_W,(float)SCR_H, 0.06f,0.07f,0.10f);
  drawStringCentered(SCR_H*0.14f, 14.0f, "ABOUT", 0.96f,0.86f,0.25f);

  float s=8.0f; float y=SCR_H*0.32f;
  char line1[64]; std::snprintf(line1,sizeof(line1),"MYSTIC MAZE %s", VERSION_NAME);
  char line2[64]; std::snprintf(line2,sizeof(line2),"DEVELOPER : %s", DEV_NAME);
  drawStringCentered(y,        s, line1, 0.90f,0.94f,0.98f);
  drawStringCentered(y+s*7,    s, line2, 0.90f,0.94f,0.98f);
  drawStringCentered(y+s*14,   s, "ENGINE   : C++ + OPENGL (GLFW + GLAD)", 0.90f,0.94f,0.98f);
  drawStringCentered(y+s*21,   s, "ASSETS   : MAZE_GHOST.PNG, OPTIONAL MENU_MUSIC.WAV", 0.90f,0.94f,0.98f);
  drawStringCentered(SCR_H - 40.0f, 6.0f, "PRESS ESC OR ENTER TO RETURN", 0.70f,0.74f,0.82f);

  renderUIOnly();
}

// ---------------- GLFW callbacks ----------------
static void framebufferSizeCB(GLFWwindow*, int w, int h){ SCR_W = (w>1)?w:1; SCR_H = (h>1)?h:1; glViewport(0,0,SCR_W,SCR_H); }
static void cursorPosCB(GLFWwindow*, double x, double y){
  static double lastX = SCR_W*0.5, lastY = SCR_H*0.5;
  if(paused || screen!=SCR_PLAY){ lastX=x; lastY=y; return; }
  double dx = x - lastX; player.yaw += (float)(dx * TURN_SENS); lastX = x; lastY = y;
}
static void keyCB(GLFWwindow* win, int key, int, int action, int){
  if(key>=0 && key<512){ if(action==GLFW_PRESS) keyDown[key]=true; if(action==GLFW_RELEASE) keyDown[key]=false; }
  if(action!=GLFW_PRESS) return;

  if(screen!=SCR_PLAY && key==GLFW_KEY_ESCAPE){ screen = SCR_MENU; return; }

  if(screen==SCR_MENU){
    if(key==GLFW_KEY_UP || key==GLFW_KEY_W)   { menuIndex = (menuIndex+4)%5; }
    if(key==GLFW_KEY_DOWN || key==GLFW_KEY_S) { menuIndex = (menuIndex+1)%5; }
    if(key==GLFW_KEY_ENTER || key==GLFW_KEY_SPACE){
      if(menuIndex==0){
        screen = SCR_PLAY;
        musicStop(); musicPlayLoop("game_music.wav");
        resetGame(); glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
      } else if(menuIndex==1){ screen = SCR_SETTINGS; }
      else if(menuIndex==2){ screen = SCR_HELP; }
      else if(menuIndex==3){ screen = SCR_ABOUT; }
      else if(menuIndex==4){ glfwSetWindowShouldClose(win, GLFW_TRUE); }
    }
    return;
  }

  if(screen==SCR_SETTINGS){
    if(key==GLFW_KEY_UP || key==GLFW_KEY_W)   { settingsIndex = (settingsIndex+1)%2; }
    if(key==GLFW_KEY_DOWN || key==GLFW_KEY_S) { settingsIndex = (settingsIndex+1)%2; }
    if(key==GLFW_KEY_LEFT || key==GLFW_KEY_A || key==GLFW_KEY_RIGHT || key==GLFW_KEY_D){
      if(settingsIndex==0){
        musicOn = !musicOn;
        if(!musicOn) musicStop();
        else { initWinMM(); musicPlayLoop("menu_music.wav"); }
      }
    }
    if(key==GLFW_KEY_ENTER || key==GLFW_KEY_SPACE){
      if(settingsIndex==0){
        musicOn = !musicOn;
        if(!musicOn) musicStop();
        else { initWinMM(); musicPlayLoop("menu_music.wav"); }
      } else { screen = SCR_MENU; }
    }
    if(key==GLFW_KEY_ESCAPE || key==GLFW_KEY_BACKSPACE){ screen = SCR_MENU; }
    return;
  }

  if(screen==SCR_HELP || screen==SCR_ABOUT){
    if(key==GLFW_KEY_ENTER || key==GLFW_KEY_SPACE || key==GLFW_KEY_BACKSPACE){ screen = SCR_MENU; }
    return;
  }

  // Gameplay
  if(key==GLFW_KEY_ESCAPE){ glfwSetWindowShouldClose(win, GLFW_TRUE); return; }
  if(key==GLFW_KEY_P){ paused=!paused; glfwSetInputMode(win, GLFW_CURSOR, paused?GLFW_CURSOR_NORMAL:GLFW_CURSOR_DISABLED); }
  if(key==GLFW_KEY_M) showMap=!showMap;
  if(key==GLFW_KEY_R && (paused||won||lost||timeup)){ resetGame(); glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED); }
}

// ---------------- main ----------------
int main(){
  std::srand((unsigned)std::time(NULL));
  generateMaze();
  player.x=(float)startX+0.5f; player.y=(float)startY+0.5f; player.yaw=0.0f; player.stamina=STAMINA_MAX;
  timeLeft = START_TIME;

  if(!glfwInit()){ std::fprintf(stderr,"GLFW init failed\n"); return 1; }
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR,3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR,3);
  glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE);

  GLFWwindow* win = glfwCreateWindow(WIN_W_INIT, WIN_H_INIT, "Mystic Maze", NULL, NULL);
  if(!win){ std::fprintf(stderr,"GLFW window failed\n"); glfwTerminate(); return 1; }
  glfwMakeContextCurrent(win);
  glfwSwapInterval(1);

  if(!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)){ std::fprintf(stderr,"Failed to load GL via GLAD\n"); return 1; }

  GLuint vs=compile(GL_VERTEX_SHADER, vsSrc);
  GLuint fs=compile(GL_FRAGMENT_SHADER, fsSrc);
  prog=link(vs,fs); glDeleteShader(vs); glDeleteShader(fs);

  glGenVertexArrays(1,&vao);
  glGenBuffers(1,&vbo);
  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*MAX_VERTS, nullptr, GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(0); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,sizeof(Vertex),(void*)0);
  glEnableVertexAttribArray(1); glVertexAttribPointer(1,3,GL_FLOAT,GL_FALSE,sizeof(Vertex),(void*)(sizeof(float)*2));
  glEnableVertexAttribArray(2); glVertexAttribPointer(2,2,GL_FLOAT,GL_FALSE,sizeof(Vertex),(void*)(sizeof(float)*5));
  glEnableVertexAttribArray(3); glVertexAttribPointer(3,1,GL_FLOAT,GL_FALSE,sizeof(Vertex),(void*)(sizeof(float)*7));
  glBindVertexArray(0);

  uModeLoc   = glGetUniformLocation(prog,"uMode");
  uScreenLoc = glGetUniformLocation(prog,"uScreen");
  uTexLoc    = glGetUniformLocation(prog,"uTex");

  verts = (Vertex*)std::malloc(sizeof(Vertex)*MAX_VERTS);
  if(!verts){ std::fprintf(stderr,"OOM verts\n"); return 1; }

  glfwGetFramebufferSize(win, &SCR_W, &SCR_H);
  glViewport(0,0,SCR_W,SCR_H);

  glfwSetFramebufferSizeCallback(win, framebufferSizeCB);
  glfwSetCursorPosCallback(win, cursorPosCB);
  glfwSetKeyCallback(win, keyCB);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  ghostTex = tryLoadGhostTexture(&ghost.aspect);

  // Start at MENU
  glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
  initWinMM();
  musicStop(); // just in case
  musicPlayLoop("menu_music.wav"); // no-op if not found

  lastTime = glfwGetTime();

  while(!glfwWindowShouldClose(win)){
    glfwPollEvents();

    glViewport(0,0,SCR_W,SCR_H);
    glClearColor(SKY[0],SKY[1],SKY[2],1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    if(screen==SCR_PLAY){
      updateLogic(win);
      BuildCounts cts = buildFrameVerts();
      renderFrame(cts);

      char title[300];
      std::snprintf(title,sizeof(title),
        "Mystic Maze  |  FPS %.1f  |  Time %02d : %02d  |  Exit: GREEN  |  %s%s%s",
        fps,
        (int)(timeLeft/60), (int)std::ceil(fmodf(timeLeft,60.0f)),
        won ? "YOU WIN!  " : "",
        lost ? "GAME OVER — Press R  " : "",
        timeup ? "TIME UP — Press R" : "");
      glfwSetWindowTitle(win, title);
    } else if(screen==SCR_MENU){
      drawMenuScreen();
      glfwSetWindowTitle(win, "Mystic Maze — Menu");
    } else if(screen==SCR_SETTINGS){
      drawSettingsScreen();
      glfwSetWindowTitle(win, "Mystic Maze — Settings");
    } else if(screen==SCR_HELP){
      drawHelpScreen();
      glfwSetWindowTitle(win, "Mystic Maze — Help");
    } else if(screen==SCR_ABOUT){
      drawAboutScreen();
      glfwSetWindowTitle(win, "Mystic Maze — About");
    }

    glfwSwapBuffers(win);
  }

  std::free(verts);
  std::free(zbuf);
  if(ghostTex) glDeleteTextures(1,&ghostTex);
  glDeleteBuffers(1,&vbo); glDeleteVertexArrays(1,&vao); glDeleteProgram(prog);
  shutdownWinMM();
  glfwTerminate();
  return 0;
}
