/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * main.c
 *
 * Code generation for function 'main'
 *
 */

/*************************************************************************/
/* This automatically generated example C main file shows how to call    */
/* entry-point functions that MATLAB Coder generated. You must customize */
/* this file for your application. Do not modify this file directly.     */
/* Instead, make a copy of this file, modify it, and integrate it into   */
/* your development environment.                                         */
/*                                                                       */
/* This file initializes entry-point function arguments to a default     */
/* size and value before calling the entry-point functions. It does      */
/* not store or use any values returned from the entry-point functions.  */
/* If necessary, it does pre-allocate memory for returned values.        */
/* You can use this file as a starting point for a main function that    */
/* you can deploy in your application.                                   */
/*                                                                       */
/* After you copy the file, and before you deploy it, you must make the  */
/* following changes:                                                    */
/* * For variable-size function arguments, change the example sizes to   */
/* the sizes that your application requires.                             */
/* * Change the example values of function arguments to the values that  */
/* your application requires.                                            */
/* * If the entry-point functions return values, store these values or   */
/* otherwise use them as required by your application.                   */
/*                                                                       */
/*************************************************************************/
/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "main.h"
#include "UpdateThetaBetaAprx_LargeData_terminate.h"
#include "UpdateThetaBetaAprx_LargeData_emxAPI.h"
#include "UpdateThetaBetaAprx_LargeData_initialize.h"

/* Function Declarations */
static void argInit_2x20_real_T(double result[40]);
static void argInit_2x3x5080_real_T(double result[30480]);
static void argInit_3x1_real_T(double result[3]);
static void argInit_3x3x20_real_T(double result[180]);
static void argInit_60x1_real32_T(float result[60]);
static void argInit_60x5080_real_T(double result[304800]);
static void argInit_6x1_real_T(double result[6]);
static float argInit_real32_T(void);
static double argInit_real_T(void);
static void argInit_struct0_T(struct0_T *result);
static void main_UpdateThetaBetaAprx_LargeData(void);

/* Function Definitions */
static void argInit_2x20_real_T(double result[40])
{
  int idx0;
  int idx1;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 2; idx0++) {
    for (idx1 = 0; idx1 < 20; idx1++) {
      /* Set the value of the array element.
         Change this value to the value that the application requires. */
      result[idx0 + (idx1 << 1)] = argInit_real_T();
    }
  }
}

static void argInit_2x3x5080_real_T(double result[30480])
{
  int idx0;
  int idx1;
  int idx2;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 2; idx0++) {
    for (idx1 = 0; idx1 < 3; idx1++) {
      for (idx2 = 0; idx2 < 5080; idx2++) {
        /* Set the value of the array element.
           Change this value to the value that the application requires. */
        result[(idx0 + (idx1 << 1)) + 6 * idx2] = argInit_real_T();
      }
    }
  }
}

static void argInit_3x1_real_T(double result[3])
{
  int idx0;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 3; idx0++) {
    /* Set the value of the array element.
       Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

static void argInit_3x3x20_real_T(double result[180])
{
  int idx0;
  int idx1;
  int idx2;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 3; idx0++) {
    for (idx1 = 0; idx1 < 3; idx1++) {
      for (idx2 = 0; idx2 < 20; idx2++) {
        /* Set the value of the array element.
           Change this value to the value that the application requires. */
        result[(idx0 + 3 * idx1) + 9 * idx2] = argInit_real_T();
      }
    }
  }
}

static void argInit_60x1_real32_T(float result[60])
{
  int idx0;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 60; idx0++) {
    /* Set the value of the array element.
       Change this value to the value that the application requires. */
    result[idx0] = argInit_real32_T();
  }
}

static void argInit_60x5080_real_T(double result[304800])
{
  int idx0;
  int idx1;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 60; idx0++) {
    for (idx1 = 0; idx1 < 5080; idx1++) {
      /* Set the value of the array element.
         Change this value to the value that the application requires. */
      result[idx0 + 60 * idx1] = argInit_real_T();
    }
  }
}

static void argInit_6x1_real_T(double result[6])
{
  int idx0;

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 6; idx0++) {
    /* Set the value of the array element.
       Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

static float argInit_real32_T(void)
{
  return 0.0F;
}

static double argInit_real_T(void)
{
  return 0.0;
}

static void argInit_struct0_T(struct0_T *result)
{
  /* Set the value of each structure field.
     Change this value to the value that the application requires. */
  argInit_6x1_real_T(result->miu3);
  argInit_6x1_real_T(result->sigma3_sq);
  argInit_6x1_real_T(result->pi);
  result->sigma1_sq = argInit_real_T();
  argInit_3x1_real_T(result->sigma2_sq);
  argInit_3x3x20_real_T(result->A);
}

static void main_UpdateThetaBetaAprx_LargeData(void)
{
  struct1_T theta_new;
  emxArray_real_T *beta_new;
  emxArray_real_T *z_mode;
  emxArray_real_T *subICmean;
  emxArray_real_T *subICvar;
  emxArray_real_T *grpICmean;
  emxArray_real_T *grpICvar;
  emxArray_real_T *G_z_dict;
  static double dv1[304800];
  double dv2[40];
  struct0_T r8;
  float fv1[60];
  static double dv3[30480];
  double err;
  emxInit_struct1_T(&theta_new);
  emxInitArray_real_T(&beta_new, 3);
  emxInitArray_real_T(&z_mode, 1);
  emxInitArray_real_T(&subICmean, 3);
  emxInitArray_real_T(&subICvar, 4);
  emxInitArray_real_T(&grpICmean, 2);
  emxInitArray_real_T(&grpICvar, 3);
  emxInitArray_real_T(&G_z_dict, 3);

  /* Initialize function 'UpdateThetaBetaAprx_LargeData' input arguments. */
  /* Initialize function input argument 'Y'. */
  /* Initialize function input argument 'X_mtx'. */
  /* Initialize function input argument 'theta'. */
  /* Initialize function input argument 'C_matrix_diag'. */
  /* Initialize function input argument 'beta'. */
  /* Call the entry-point 'UpdateThetaBetaAprx_LargeData'. */
  argInit_60x5080_real_T(dv1);
  argInit_2x20_real_T(dv2);
  argInit_struct0_T(&r8);
  argInit_60x1_real32_T(fv1);
  argInit_2x3x5080_real_T(dv3);
  UpdateThetaBetaAprx_LargeData(dv1, dv2, &r8, fv1, dv3, argInit_real_T(),
    argInit_real_T(), argInit_real_T(), argInit_real_T(), argInit_real_T(),
    argInit_real_T(), &theta_new, beta_new, z_mode, subICmean, subICvar,
    grpICmean, grpICvar, &err, G_z_dict);
  emxDestroyArray_real_T(G_z_dict);
  emxDestroyArray_real_T(grpICvar);
  emxDestroyArray_real_T(grpICmean);
  emxDestroyArray_real_T(subICvar);
  emxDestroyArray_real_T(subICmean);
  emxDestroyArray_real_T(z_mode);
  emxDestroyArray_real_T(beta_new);
  emxDestroy_struct1_T(theta_new);
}

int main(int argc, const char * const argv[])
{
  (void)argc;
  (void)argv;

  /* Initialize the application.
     You do not need to do this more than one time. */
  UpdateThetaBetaAprx_LargeData_initialize();

  /* Invoke the entry-point functions.
     You can call entry-point functions multiple times. */
  main_UpdateThetaBetaAprx_LargeData();

  /* Terminate the application.
     You do not need to do this more than one time. */
  UpdateThetaBetaAprx_LargeData_terminate();
  return 0;
}

/* End of code generation (main.c) */
