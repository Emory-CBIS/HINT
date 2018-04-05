/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * permute.c
 *
 * Code generation for function 'permute'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "permute.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void permute(const emxArray_real_T *a, emxArray_real_T *b)
{
  int plast;
  unsigned int outsz[3];
  unsigned int insz[3];
  boolean_T b_b;
  int k;
  boolean_T exitg1;
  int iwork[3];
  static const signed char iv0[3] = { 2, 1, 3 };

  int inc[3];
  static const signed char iv1[3] = { 1, 0, 2 };

  int isrc;
  int exitg2;
  for (plast = 0; plast < 3; plast++) {
    insz[plast] = (unsigned int)a->size[plast];
  }

  outsz[0] = 1U;
  outsz[1] = insz[0];
  outsz[2] = insz[2];
  plast = b->size[0] * b->size[1] * b->size[2];
  b->size[0] = 1;
  b->size[1] = (int)insz[0];
  b->size[2] = (int)insz[2];
  emxEnsureCapacity((emxArray__common *)b, plast, sizeof(double));
  b_b = true;
  if (!((a->size[0] == 0) || (a->size[2] == 0))) {
    plast = 0;
    k = 0;
    exitg1 = false;
    while ((!exitg1) && (k + 1 < 4)) {
      if (a->size[iv0[k] - 1] != 1) {
        if (plast > iv0[k]) {
          b_b = false;
          exitg1 = true;
        } else {
          plast = iv0[k];
          k++;
        }
      } else {
        k++;
      }
    }
  }

  if (b_b) {
    plast = a->size[0] * a->size[2];
    for (k = 0; k + 1 <= plast; k++) {
      b->data[k] = a->data[k];
    }
  } else {
    for (plast = 0; plast < 3; plast++) {
      iwork[plast] = 1;
    }

    for (k = 0; k < 2; k++) {
      iwork[k + 1] = iwork[k] * (int)insz[k];
    }

    for (plast = 0; plast < 3; plast++) {
      inc[plast] = iwork[iv1[plast]];
    }

    for (plast = 0; plast < 3; plast++) {
      iwork[plast] = 0;
    }

    plast = 0;
    do {
      isrc = 0;
      for (k = 0; k < 2; k++) {
        isrc += iwork[k + 1] * inc[k + 1];
      }

      b->data[plast] = a->data[isrc];
      plast++;
      k = 1;
      do {
        exitg2 = 0;
        iwork[k]++;
        if (iwork[k] < (int)outsz[k]) {
          exitg2 = 2;
        } else if (k + 1 == 3) {
          exitg2 = 1;
        } else {
          iwork[1] = 0;
          k = 2;
        }
      } while (exitg2 == 0);
    } while (!(exitg2 == 1));
  }
}

/* End of code generation (permute.c) */
