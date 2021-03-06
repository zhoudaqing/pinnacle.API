#' Get Fixtures
#'
#' @param sportname The sport name for which to retrieve the fixtures
#' @param leagueIds integer vector with league IDs.
#' @param since Default=NULL, numeric This is used to receive incremental updates.
#' Use the value of last from previous fixtures response.
#' @param isLive Default=FALSE, boolean if TRUE retrieves ONLY live events if FALSE retrieved all events
#'
#' @return returns a data frame with columns:
#' \itemize{
#' \item SportID
#' \item Last
#' \item League
#' \item LeagueID
#' \item EventID
#' \item StartTime
#' \item HomeTeamName
#' \item AwayTeamName
#' \item Rotation Number
#' \item Live Status
#' \item Status
#' \item Parlay Status
#' }
#' @import httr
#' @importFrom jsonlite fromJSON
#' @export
#'
#' @examples
#' \donttest{
#' SetCredentials("TESTAPI","APITEST")
#' AcceptTermsAndConditions(accepted=TRUE)
#' GetFixtures(sportname = "Badminton",leagueIds = 191545)}



GetFixtures <-
  function(sportname,leagueIds,since=NULL,isLive=0){

    CheckTermsAndConditions()
    ## retrieve sportid
    if (missing(sportname))
      stop("Provide a Sport Name")
    
    sportId <- GetSports(FALSE)[,"SportID"][sportname== GetSports(FALSE)[,"SportName"]]
    ##
    
    
    PossibleLeagueIds = GetLeaguesByID(sportId)
    PossibleLeagueIds = PossibleLeagueIds$LeagueID[PossibleLeagueIds$LinesAvailable==1]
    if(missing(leagueIds))
      leagueIds <- PossibleLeagueIds
    
    if(any(!(leagueIds %in% PossibleLeagueIds))) {
      warning(paste("The Following leagues do not have bettable lines and have been excluded from the output:",paste(leagueIds[!(leagueIds %in% PossibleLeagueIds)], collapse=",")))
      leagueIds = intersect(leagueIds,PossibleLeagueIds)
    }
    
    r <- GET(paste0(.PinnacleAPI$url ,"/v1/fixtures"),
             add_headers(Authorization= authorization(),
                         "Content-Type" = "application/json"),
             query = list(sportId=sportId,
                          leagueIds = paste(leagueIds,collapse=','),
                          since=since,
                          isLive=isLive*1))
    res <-  jsonlite::fromJSON(content(r,type="text"))

    target.cols <- c("id", "starts", "home",
                     "away", "rotNum", "liveStatus",
                     "status", "parlayRestriction")

    out <- cbind(res$sportId,
                 res$last,
                 do.call(rbind,Map(function(id,events)
                   data.frame(idEvent =id,events[,target.cols]) ,
                   res$league$id,res$league$events)))
    colnames(out) <- c("SportID","Last","LeagueID","EventID",
                       "StartTime","HomeTeamName","AwayTeamName",
                       "RotationNumber","LiveStatus","Status","ParlayStatus")
    out

  }
