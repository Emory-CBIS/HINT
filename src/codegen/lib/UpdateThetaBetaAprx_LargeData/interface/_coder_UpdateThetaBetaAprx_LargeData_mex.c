/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_UpdateThetaBetaAprx_LargeData_mex.c
 *
 * Code generation for function '_coder_UpdateThetaBetaAprx_LargeData_mex'
 *
 */

/* Include files */
#include "_coder_UpdateThetaBetaAprx_LargeData_api.h"
#include "_coder_UpdateThetaBetaAprx_LargeData_mex.h"

/* Function Declarations */
static void c_UpdateThetaBetaAprx_LargeData(int32_T nlhs, mxArray *plhs[9],
  int32_T nrhs, const mxArray *prhs[11]);

/* Function Definitions */
static void c_UpdateThetaBetaAprx_LargeData(int32_T nlhs, mxArray *plhs[9],
  int32_T nrhs, const mxArray *prhs[11])
{
  int32_T n;
  const mxArray *inputs[11];
  const mxArray *outputs[9];
  int32_T b_nlhs;

  /* Check for proper number of arguments. */
  if (nrhs != 11) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal, "EMLRT:runTime:WrongNumberOfInputs",
                        5, 12, 11, 4, 29, "UpdateThetaBetaAprx_LargeData");
  }

  if (nlhs > 9) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal,
                        "EMLRT:runTime:TooManyOutputArguments", 3, 4, 29,
                        "UpdateThetaBetaAprx_LargeData");
  }

  /* Temporary copy for mex inputs. */
  for (n = 0; n < nrhs; n++) {
    inputs[n] = prhs[n];
  }

  /* Call the function. */
  UpdateThetaBetaAprx_LargeData_api(inputs, outputs);

  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    b_nlhs = 1;
  } else {
    b_nlhs = nlhs;
  }

  emlrtReturnArrays(b_nlhs, plhs, outputs);

  /* Module termination. */
  UpdateThetaBetaAprx_LargeData_terminate();
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs, const mxArray
                 *prhs[])
{
  mexAtExit(UpdateThetaBetaAprx_LargeData_atexit);

  /* Initialize the memory manager. */
  /* Module initialization. */
  UpdateThetaBetaAprx_LargeData_initialize();

  /* Dispatch the entry-point. */
  c_UpdateThetaBetaAprx_LargeData(nlhs, plhs, nrhs, prhs);
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  return emlrtRootTLSGlobal;
}

/* End of code generation (_coder_UpdateThetaBetaAprx_LargeData_mex.c) */
