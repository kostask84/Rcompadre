#' Collapse a matrix model to a smaller number of stages
#' 
#' This function collapses a matrix model to a smaller number of stages. For
#' instance, to compare properties of multiple projection matrices with
#' different numbers of stages, one might first collapse those matrices to a
#' standardized set of stages (e.g. propagule, pre-reproductive, reproductive,
#' and post-reproductive). The vital rates in the collapsed matrix are a
#' weighted average of the vital rates from the relevant stages of the original
#' matrix, weighted by the relative proportion of each stage class expected at
#' the stable distribution.\cr\cr
#' Note: this function is only valid for models without clonality.
#'
#' @export
#' @param matU Survival matrix
#' @param matF Fecundity matrix
#' @param matC A clonality matrix
#' @param collapse A character vector giving the mapping between the stages of
#'   the original matrix and the desired stages of the collapsed matrix. The
#'   indices of \code{collapse} correspond to the desired stages of the
#'   collapsed matrix, and each element of \code{collapse} gives the stage index
#'   (e.g. "2") or range of stage indices (e.g. "2-3") from the original matrix
#'   that correspond to the relevant stage index of the collapsed matrix.
#' @return A list of three containing the collapsed projection matrix
#'   \code{matA}, collapsed survival matrix \code{matU}, and collapsed fecundity
#'   matrix \code{matF}.
#' @author Rob Salguero-Gómez <rob.salguero@@zoo.ox.ac.uk>
#' @references Salguero-Gomez, R. & Plotkin, J. B. (2010) Matrix dimensions
#'   bias demographic inferences: implications for comparative plant demography.
#'   The American Naturalist 176, 710-722.
#' @examples
#' matU <- matrix(c(0.2581, 0.1613, 0.1935, 0.2258, 0.1613, 0.0408, 0.2857,
#'                  0.4286, 0.102, 0.0816, 0.0385, 0.0385, 0.2692, 0.2308,
#'                  0.3462, 0, 0.0625, 0.125, 0.25, 0.5625, 0.1061, 0.1608,
#'                  0.2637, 0.1801, 0.2058),
#'                  nrow = 5, byrow = FALSE)
#' matF <- matrix(c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
#'                  0, 0, 0, 0, 2.75, 1.75, 0, 0),
#'                  nrow = 5, byrow = FALSE)
#' matC <- matrix(rep(0, 25), nrow = 5, byrow = TRUE) 
#' collapse1 <- c("1-2", "3-4", "5")
#' collapseMatrix(matU, matF, matC, collapse1)
#'
#' # collapse2 <- c("1-2", "3-4-5")
#' # collapse3 <- c("1-2-3-4-5")
collapseMatrix <- function(matU, matF, matC, collapse) {
  matA <- matU + matF + matC
  if (any(is.na(matA))) {
    stop("Cannot collapse projection matrix containing NAs", call. = FALSE)
  }
  originalDim <- dim(matA)[1]
  collapseDim <- length(collapse)
  P <- matrix(0, nrow = collapseDim , ncol = originalDim)

  splitCollapseUnique <- strsplit(collapse, "-")
  for (i in 1:collapseDim) {
    columns <- as.numeric(splitCollapseUnique[[i]])
    if (!is.na(columns[1])) {
      P[i, (columns[1]:columns[length(columns)])] <- 1
    }
  }

  Q <- t(P)
  w <- Re(eigen(matA)$vectors[ ,which.max(Re(eigen(matA)$values))])
  w <- w / sum(w)

  columns <- which(colSums(Q) > 1)
  for (j in columns) {
    rows <- which(Q[,j] == 1)
    for (i in rows) {
      Q[i,j] <- w[i] / sum(w[rows])
    }
  }
  
  collapseA <- P %*% matA %*% Q
  collapseU <- P %*% matU %*% Q
  collapseF <- P %*% matF %*% Q
  collapseC <- P %*% matC %*% Q
  
  return(list(matA = collapseA, 
              matU = collapseU, 
              matF = collapseF,
              matC = collapseC))
}
