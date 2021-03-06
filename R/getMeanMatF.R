#' Calculates a population-specific grand mean fecundity matrix for each set of
#' matrices in a COM(P)ADRE database object
#'
#' This function takes a COM(P)ADRE database object and calculates a grand mean
#' fecundity matrix for each unique population (a mean of all
#' population-specific fecundity matrices, including fecundity matrices for
#' which \code{MatrixComposite == 'Mean'}). Here, a unique study population is
#' defined as a unique combination of the metadata columns Authors,
#' YearPublication, DOI.ISBN, SpeciesAuthor, MatrixPopulation, and
#' MatrixDimension. The main purpose of this function is to identify stage
#' classes that are \emph{potentially} reproductive (i.e. the absense of
#' fecundity in a given stage class and year does not necessarily indicate that
#' the stage in question is non-reproductive).
#'
#' @param db A COM(P)ADRE database object.
#' @return Returns a list which contains the mean fecundity matrix associated
#'   with a given row of the database, or NA if there is only a single matrix
#'   from the relevant population within the db.
#' @author Danny Buss <dlb50@@cam.ac.uk>
#' @author Julia Jones <juliajones@@biology.sdu.dk>
#' @author Iain Stott <stott@@biolgy.ox.ac.uk>
#' @author Patrick Barks <patrick.barks@@gmail.com>
#' @examples
#' \dontrun{
#' # print set of matrices (A, U, F, C) associated with row 2 of database
#' compadre$mat[[2]]
#'
#' # create list of meanMatFs
#' meanF <- getMeanMatF(compadre)
#'
#' # print meanMatF associated with row 2 of database
#' compadre_with_meanF$mat[[2]]
#' }
#' @export
#' @importFrom rlang .data
getMeanMatF <- function(db) {
  
  # create a unique identifier for each population in the database
  db@metadata$PopId <- as.numeric(as.factor(paste(
    db@metadata$Authors,
    db@metadata$YearPublication,
    db@metadata$DOI.ISBN,
    db@metadata$SpeciesAuthor,
    db@metadata$MatrixPopulation,
    db@metadata$MatrixDimension
  )))
  
  # subset database to only mean matrices that are divided,
  # and create unique row ID
  ssdb_mean <- subsetDB(db, MatrixSplit == "Divided")
  ssdb_mean@metadata$RowId <- seq_len(nrow(ssdb_mean@metadata)) 
  
  # function to return a mean mean matF given PopId
  meanMatF <- function(PopIdFocal) {
    RowId <- subset(ssdb_mean@metadata, PopId == PopIdFocal)$RowId
    meanMatFs <- lapply(RowId, function(y) ssdb_mean@mat[[y]]@matF)
    
    if (length(meanMatFs) == 1) {        # if only one meanMatF for given PopId
      return(NA)
    } else {                             # if multiple meanMatF for given PopId
      meanMatFsSum <- matrix(0,
                             nrow = nrow(meanMatFs[[1]]),
                             ncol = ncol(meanMatFs[[1]]))
      
      for(i in 1:length(meanMatFs)) {
        meanMatFsSum <- meanMatFsSum + meanMatFs[[i]]
      }
      
      return(meanMatFsSum / length(meanMatFs))
    }
  }
  
  # create vector of unique PopIds, and list of corresponding meanMatFs
  unique_study_pop <- sort(unique(db@metadata$PopId))
  unique_mean_mat_F <- lapply(unique_study_pop, meanMatF)

  # function to return meanMatF corresponding to given row number of db
  appendMeanMatF <- function(i) {
    PopId <- db@metadata$PopId[i]
    index_mean_mat_F <- which(unique_study_pop == PopId)
    return(unique_mean_mat_F[[index_mean_mat_F]])
  }
  
  # create list of meanMatFs for each row of database
  meanMatList <- lapply(1:nrow(db@metadata), appendMeanMatF)
  
  return(meanMatList)
}