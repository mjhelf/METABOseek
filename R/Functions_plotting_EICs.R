#' EICgeneral
#' 
#' wrapper function to plot multiple EICs
#' 
#' 
#' @param rtmid vector of retention time values (not ranges). If length >1, 
#' multiple plots are called (multiple pages in pdf file)
#' @param mzmid vector of mz values (not ranges). 
#' Has to be same length as \code{rtmid}
#' @param glist a named list of grouped file names 
#' (as supplied in $grouping of rawLayout objects)
#' @param cols integer, number of columns in plot. if NULL, 
#' grid can be defined externally
#' @param colrange character(1), color range function used for line colors,
#'  OR a list of data.frames, see \code{Details}
#' @param transparency numeric(1), alpha (range 0..1) for transparency of lines
#' @param RTall if TRUE, entire RT range will be plotted
#' @param TICall if TRUE, TIC will be plotted instead of EIC
#' @param rtw retention time window +/- rtmid in seconds that will be plotted
#' @param ppm mz window +/- mzmid in ppm that will be plotted
#' @param rdata named list of xcmsRaw objects
#' @param pdfFile character - if not NULL, plotting result will be saved in a 
#' pdf file with this name.
#' @param leadingTIC if TRUE, a TIC plot is made before the EIC plots 
#' (e.g. as first page of pdf file)
#' @param midline if TRUE, dotted vertical line should be plotted at feature rt
#' @param lw line width for plot lines
#' @param yzoom zoom factor into y-axis
#' @param cx character expansion factor (font size)
#' @param adducts numeric() of mass shifts to be added to feature masses
#' @param RTcorrect if not NULL, this RTcorr object will be used to 
#' adjust retention times.
#' @param importEIC a \code{\link{multiEICplus}()} output object to plot here, If NULL,
#'  \code{multiEICplus()} is called with the other supplied parameters 
#' @param globalYmax if TRUE, all EICs are scaled to the maximum value across all 
#' plotting groups instead of the maximum within each group
#' @param subtitles subtitles for each EIC, must be character of 
#' same length as rtmid and mzmid or NULL
#' @param raise if TRUE, EIC will be plotted with y axis going to 
#' -0.02*max(ylim) so that EICs with 0 intensity are visible.
#' @param relPlot if TRUE, y-axis will show relative intensities
#' @param margins manual setting for plot margins (par$mar)
#' @param ylabshift shift horizontal position of y axis label 
#' @param RescaleExclude character(), exclude this group from rescaling, or NULL to use all
#' 
#' @return sends a grouped EIC plot to the current plotting device, or 
#' generates a .pdf file
#' 
#' @details 
#' \describe{
#' \item{colrange}{A named list with the same structure as \code{glist},
#' but with a data.frame in each list element with row order corresponding to 
#' items in the list elements of \code{glist} and columns \code{color} and \code{label},
#' specifying the EIC color and legend label for each EIC trace.
#' }
#' }
#' 
#' @export
EICgeneral <- function(rtmid,
                       mzmid,
                       glist,
                       cols = NULL,
                       colrange = "Mseek.colors",
                       transparency = 1,
                       RTall = FALSE,
                       TICall = FALSE,
                       rtw = 30,
                       ppm = 5,
                       rdata,
                       pdfFile = "plotOutput.pdf",
                       leadingTIC = T,
                       lw = 1,
                       adducts = c(0),
                       cx = 1,
                       midline = T,
                       yzoom = 1,
                       RTcorrect = NULL,
                       importEIC = NULL,
                       globalYmax = FALSE,
                       subtitles = NULL,
                       raise = F,
                       relPlot = F,
                       margins = NULL,
                       ylabshift = 0,
                       RescaleExclude = NULL
){
  #number of plot rows
  if(!is.null(cols)){
  rows <- ceiling(length(glist)/cols)
  }else{
    rows <-1}
  
  if(!is.list(colrange)){
  #make color scales for each group, color shades based on group with most members
  colvec <- do.call(colrange,
                    list(n=max(sapply(glist,length)), alpha = transparency))
  colrs <- list()
  for(i in 1:length(glist)){
    colrs[[i]] <- data.frame(color = colvec[1:length(glist[[i]])],
                             label = sub("^([^.]*).*", "\\1",basename(glist[[i]])),
                             stringsAsFactors = FALSE)

  }}
  else{
    colrs <- colrange
  }
  
 # print(colrs)
  
  #generate rt boundary df
  if(any(RTall, is.null(rtmid))){ # any can handle NULL, seems more flexible than ||
    rtmid <- NULL
    rtx <- NULL
  }else{
    rtx <- data.frame(rtmin = rtmid - rtw,
                      rtmax = rtmid + rtw)
  }  
  
  #generate mz boundary df
  if(any(TICall, is.null(mzmid)) ){
    mzmid <- if(!is.null(rtmid)){rep(100,length(rtmid))}else{100}
    mzx <- data.frame(mzmin = mzmid-1,
                      mzmax = mzmid+1)
    titx <- if(!is.null(rtmid)){rep("TICs",length(rtmid))}else{"TICs"}
    tictog <- TRUE
  }else{
    tictog <- FALSE
    mzx <- data.frame(mzmin = mzmid - mzmid*ppm*1e-6,
                      mzmax = mzmid + mzmid*ppm*1e-6)
    titx <- EICtitles(mzmid, rtmid, ppm)
  }
  
 
  
  if(length(titx) != length(subtitles)){ subtitles <-NULL}
  
  
  
  #optionally export to pdf
  if(!is.null(pdfFile)){
    if(is.null(cols)){
      rows <- ceiling(length(glist)/5)
    
      cols <-1}
    pdf(pdfFile,
        6*cols,
        6*ceiling(length(glist)/cols)+2
    )}
  
  #optionally plot TICs first (page 1 in pdf)
  if(leadingTIC){  
    EICsTIC <- multiEIC(rawdata= rdata[basename(names(rdata)) %in% basename(unlist(glist))],
                        mz = mzx[1,],
                        rt = NULL,
                        rnames = "1", #major item names
                        byFile = F,#if true, table will be sorted by rawfile, otherwise by feature
                        RTcorr = RTcorrect  
    )
    
    
    
    yl <- if(!is.null(globalYmax) 
             && globalYmax){matrix(c(rep(0, length(EICsTIC)),
                                     sapply(EICsTIC, function(x){ max(unlist(x[,"tic"])) })), ncol = 2, byrow = F)}else{NULL}
    
    groupPlot(EIClist = EICsTIC,
              grouping = glist,
              plotProps = list(TIC = T, #settings for single plots
                               cx = cx,
                               colr = colrs,
                               lw = lw,
                               midline = NULL,
                               ylim = yl, #these should be data.frames or matrices of nrow = number of plotted features
                               xlim = NULL,
                               yzoom = 1),
              compProps = list(mfrow=c(rows,cols), #par options for the composite plot
                               oma=c(0,2,4,0),
                               xpd=NA, bg="white",
                               header =  "TICs",
                               header2 = NULL,
                               pdfFile = NULL,
                               pdfHi = 6*rows,
                               pdfWi = 6*cols,
                               cx = cx,
                               adductLabs = 0),
              raise,
              relPlot,
              margins,
              ylabshift
    )
  }
  
  if(is.null(importEIC)){
  EICs <- multiEICplus(rawdata= rdata[basename(names(rdata)) %in% basename(unlist(glist))],
                       mz = mzx,
                       rt = if(is.null(RTcorrect)){rtx}else{NULL},
                       rnames = row.names(mzmid), #major item names
                       byFile = F, #if true, table will be sorted by rawfile, otherwise by feature
                       adducts,
                       RTcorr = RTcorrect
  )}
  else{
    EICs <- importEIC
  }
  
  if(!is.null(RescaleExclude) 
     && length(na.omit(match(RescaleExclude,names(glist)))) > 0
     && length(na.omit(match(RescaleExclude,names(glist)))) < length(glist)){
   
    excludedfiles <- unlist(glist[match(RescaleExclude,names(glist))])
     
  }else{
    excludedfiles <- character(0)
  }
  
  if(TICall){
    if(is.null(rtx) || length(EICs) %% nrow(rtx) != 0 ){
      
    yl <- if(!is.null(globalYmax) 
             && globalYmax){matrix(c(rep(0, length(EICs)),
                                     sapply(EICs, function(x){ max(unlist(x[,"tic"])) })), ncol = 2, byrow = F)}else{NULL}
    }
    else{
      suppressWarnings({
      yl <- if(!is.null(globalYmax) 
               && globalYmax){matrix(c(rep(0, length(EICs)),
                                       mapply(function(x, rt){ max(unlist(x[,"tic"])[unlist(x[,"rt"]) >= max(c(min(rt),min(unlist(x[,"rt"])))) & unlist(x[,"rt"]) <= min(c(max(rt),max(unlist(x[,"rt"]))))])}, x = EICs, rt = as.list(as.data.frame(t(as.matrix(rtx))))  )), ncol = 2, byrow = F)}else{NULL}
    }) #warnings occur if all scans are out of given rt range
    }
    
    }else{
    #make sure the EICs all get scaled to their highest intensity across all adducts
    if(is.null(rtx)  || length(EICs) %% nrow(rtx) != 0  ){
    maxys <- Biobase::rowMax(matrix(sapply(EICs, function(x){ max(unlist(x[which(!rownames(x) %in% excludedfiles),"intensity"])) }), ncol = length(adducts), byrow = F))
    }else{
      suppressWarnings({
      maxys <- Biobase::rowMax(matrix(mapply(function(x, rt){
        
        subsel <- which(!rownames(x) %in% excludedfiles)
        max(unlist(x[subsel,"intensity"])[unlist(x[subsel,"rt"]) >= max(c(min(rt),min(unlist(x[subsel,"rt"])))) 
                                    & unlist(x[subsel,"rt"]) <= min(c(max(rt),max(unlist(x[subsel,"rt"]))))])},
        x = EICs, rt = as.list(as.data.frame(t(as.matrix(rtx))))  ), ncol = length(adducts), byrow = F))
      
      }) #warnings occur if all scans are out of given rt range
    }
    
    yl <- if(!is.null(globalYmax) && globalYmax){matrix(c(rep(0, length(EICs)),rep(maxys, length(adducts))), ncol = 2, byrow = F)}else{NULL}
}
  groupPlot(EIClist = EICs,
            grouping = glist,
            plotProps = list(TIC = tictog, #settings for single plots
                             cx = cx,
                             colr = colrs,
                             xlim = rtx,
                             ylim = yl, #these should be data.frames or matrices of nrow = number of plotted features
                             lw = lw,
                             midline = if(midline){rtmid}else{NULL},
                             yzoom = yzoom),
            compProps = list(mfrow=c(rows,cols), #par options for the composite plot
                             oma=c(0,2,4,0),
                             xpd=NA, bg="white",
                             header =  titx,
                             header2 = subtitles,
                             pdfFile = NULL,
                             pdfHi = 6*rows,
                             pdfWi = 6*cols,
                             cx = cx,
                             adductLabs = adducts),
            raise,
            relPlot,
            margins,
            ylabshift,
            RescaleExclude
  )
  if(!is.null(pdfFile)){dev.off()}
  
  
  
}


#' EICtitles
#' 
#' helper function to generate titles for EICgeneral
#' 
#' 
#' @param rts vector of retention time values (not ranges)
#' @param mzs vector of mz values (not ranges)
#' @param ppm mz window +/- mzmid in ppm that will be plotted
#' 
#' @return a character vector with plot titles of same length as 
#' \code{rts} and \code{mzs}
#' 
EICtitles <- function(mzs, rts, ppm){
  
  if(!is.null(ppm)){
  numbs <- matrix(mapply(sprintf,matrix(c(mzs,
                                          mzs-mzs*ppm*1e-6,
                                          mzs+mzs*ppm*1e-6),ncol=3),
                         MoreArgs = list(fmt = "%.5f")),
                  ncol=3)
  
  titx <- paste0('m/z range: ',numbs[,1], " +/- ", 
                 format(ppm, scientific = F),
                 " ppm (", numbs[,2]," - ", numbs[,3],")",
                 if(!is.null(rts)){
                   paste0(
                     " @ RT: ", sprintf( "%.2f", rts/60), " min",
                     " (", sprintf("%.1f", rts)," sec)")})
  }
  else{
    numbs <- sprintf("%.5f", mzs)
    
    titx <- paste0('m/z: ',numbs, 
                   if(!is.null(rts)){
                     paste0(
                       " @ RT: ", sprintf( "%.2f", rts/60), " min",
                       " (", sprintf("%.1f", rts)," sec)")})
    
    
  }
  return(titx)
  
}

#' groupPlot
#' 
#' generate multiple EICs on one page
#' 
#' 
#' @param EIClist list of EICs from \code{\link{multiEIC}()} or \code{\link{multiEICplus}()}
#' @param grouping a named list of grouped file names (as supplied in $grouping of rawLayout objects)
#' @param plotProps a list of settings for the individual plots, see \code{Details}
#' @param compProps layoout options for the composite plot, see \code{Details}
#' @param raise if TRUE, EIC will be plotted with y axis going to -0.02*max(ylim) so that EICs with 0 intensity are visible.
#' @param relPlot if TRUE, y-axis will show relative intensities
#' @param margins manual setting for plot margins (par$mar)
#' @param ylabshift shift horizontal position of y axis label 
#' @param RescaleExclude character(), exclude this group from rescaling, or NULL to use all
#' 
#' @return sends a grouped EIC plot to the current plotting device
#' 
#' @details 
#' \describe{
#' \item{plotProps}{A list with these elements:
#' \itemize{
#' \item \code{TIC} if TRUE, TIC instead of EIC
#' \item \code{cx} numeric(1) font size (character expansion) factor
#' \item \code{colr} color range (actual vector of color values)
#' \item \code{ylim} data.frame or matrix of nrow = number of plotted features,
#'  with min and max visible rt value (in seconds) for each feature
#' \item \code{xlim} data.frame or matrix of nrow = number of plotted features,
#'  with min and max visible intensity value for each feature
#' \item \code{midline} numeric() of y-axis positions where a dotted vertical 
#' line should be plotted
#' \item \code{lw} line width for plot lines
#' \item \code{yzoom} zoom factor into y-axis
#' }
#' }
#' \item{compProps}{
#' \itemize{
#' \item \code{mfrow} integer(2) rows and columns for plotting (cf. par(), mfrow)
#' \item \code{oma} numeric(4) outer margins (cf. par(), oma)
#' \item \code{xpd} drawing outside of plot region, cf. par(), xpd
#' \item \code{bg} background color, cf. par(), bg
#' \item \code{header} First (title) line of composite plot
#' \item \code{header2} Subtitle line of composite plot
#' \item \code{pdfFile} character - if not NULL, plotting result will be saved in a pdf file with this name.
#' \item \code{pdfHi} pdf height in inches
#' \item \code{pdfWi} pdf width in inches
#' \item \code{cx} numeric(1) font size (character expansion) factor
#' \item \code{adductLabs} adduct labels (nonfunctional)
#' }
#' }
#' }
#' 
#' @export
groupPlot <- function(EIClist,
                      grouping,
                      plotProps = list(TIC = TRUE, #settings for single plots
                                       cx = 1,
                                       colr = topo.colors(nrow(EIClist[[1]]), alpha=1),
                                       ylim = NULL, #these should be data.frames or matrices of nrow = number of plotted features
                                       xlim = NULL,
                                       lw = 1,
                                       midline = 100,
                                       yzoom = 1),
                      compProps = list(mfrow=c(1,2), #par options for the composite plot
                                       oma=c(0,2,8,0),
                                       xpd=NA, bg=NA,
                                       header =  paste0(names(EIClist)),
                                       header2 = NULL,
                                       pdfFile = NULL,
                                       pdfHi = 6,
                                       pdfWi = 12,
                                       cx = 1,
                                       adductLabs = c("0","1","2")),
                      raise = F,
                      relPlot = F,
                      margins = NULL,
                      ylabshift = 0,
                      RescaleExclude = NULL
){
  
  #majoritem is the EIClist top level (typically by mz, but could be)
  
 
  if(!is.null(compProps$pdfFile)){pdf(compProps$pdfFile,compProps$pdfWi,compProps$pdfHi)}
  
  if(!is.null(compProps$header)){
    
    autosize <- compProps$cx*1.5
    while(max(strwidth(compProps$header, units = "figure", cex = autosize, font = 2)) > 1){
      autosize <- autosize*0.975
    }
  }
  
  nrowcheck <- if(!is.null(nrow(EIClist))){nrow(EIClist)}else {1}
  
  for(majoritem in c(1:nrowcheck)){
    
    #adductLabs legend does not work yet
    #if(length(compProps$adductLabs)>1){compProps$mfrow[1] <- compProps$mfrow[1]+1}
    
    if(length(compProps$mfrow) > 1){
      par(mfrow=compProps$mfrow)
    }
    
    par(#mfrow=compProps$mfrow,
        oma=compProps$oma,
        xpd=compProps$xpd,
        bg=compProps$bg,
        mar = if(is.null(margins) ){ c(2.6*(1+(compProps$cx-1)/2),4.1*(1+(compProps$cx-1)/4),4.1,2.1)}else{margins})
    # layout(t(as.matrix(c(1,2))))
    
    for(plotgroup in c(1:length(grouping))){
      #par(mfrow=c(1,2))
      items = grouping[[plotgroup]]
      
      preminoritem <- if(nrowcheck ==1){EIClist}else{EIClist[majoritem,]}
      
      minoritem <- subsetEICs(preminoritem,
                              items)
      #minoritem <- if(length(items) == 1){t(as.matrix(EIClist[[majoritem]][items,]))}else{EIClist[[majoritem]][items,]}
      #if(length(items) == 1){row.names(minoritem) <- items}
      
      xlimes = if (is.null(plotProps$xlim)){c(min(unlist(minoritem$EIClist[[1]][,'rt'])),
                                            max(unlist(minoritem$EIClist[[1]][,'rt'])))/60}
      else{c(min(plotProps$xlim[majoritem,]), max(plotProps$xlim[majoritem,]))/60}
      
      ### by default, only the visible part of the spectrum will be used to determine y-max
      
      
      if(!is.null(plotProps$ylim) && !names(grouping)[plotgroup] %in% RescaleExclude){
        ylimes = c(0,1)
        try({
        ylimes = c(min(plotProps$ylim[majoritem,]), max(plotProps$ylim[majoritem,]))
        })
      }else if(plotProps$TIC){
        mm <- 1
          for(k in 1:length(minoritem$EIClist)){
            mm <- max(mm,
                      suppressWarnings({
                      max(unlist(minoritem$EIClist[[k]][,"tic"])[which(unlist(minoritem$EIClist[[k]][,"rt"]) >= min(xlimes)*60 
                                                                       & unlist(minoritem$EIClist[[k]][,"rt"]) <= max(xlimes)*60)])
          }) #warnings occur if all scans are out of given rt range
                      )
          }
        ylimes = c(0,mm)
        }
      else{
        mm <- 1
        for(k in 1:length(minoritem$EIClist)){
          mm <- max(mm,
                    suppressWarnings({
                    max(unlist(minoritem$EIClist[[k]][,"intensity"])[which(unlist(minoritem$EIClist[[k]][,"rt"]) >= min(xlimes)*60 
                                                                     & unlist(minoritem$EIClist[[k]][,"rt"]) <= max(xlimes)*60)])
                    }) #warnings occur if all scans are out of given rt range
                    )
        }
        ylimes = c(0,mm)
      }
      
      if(raise){ylimes[1] <- -0.02*max(ylimes)}

      EICplot(EICs = minoritem$EIClist, cx = plotProps$cx, 
              ylim = ylimes, 
              xlim = xlimes,
              colr = if(is.list(plotProps$colr)){plotProps$colr[[plotgroup]]$color}
              else{plotProps$colr[1:nrow(minoritem$EIClist[[1]])]},
              legendtext = if(is.list(plotProps$colr)){plotProps$colr[[plotgroup]]}
              else{paste(sub("^([^.]*).*", "\\1",basename(row.names(minoritem$EIClist[[1]]))))},
              heading = names(grouping)[plotgroup],
              relto = if(relPlot){max(ylimes)}else{NULL},
              TIC = plotProps$TIC,
              lw = plotProps$lw,
              midline = plotProps$midline[majoritem],
              yzoom = plotProps$yzoom,
              ylabshift = ylabshift
              #mfrow=c(1,2)
      ) 
      # }
      
    }
    
    if(!is.null(compProps$header)){
    
      title(main = compProps$header[majoritem], outer=T,line=2, cex.main=autosize, font = 2)}
    
 
    
    if(!is.null(compProps$header2)){mtext(compProps$header2[majoritem], side=3, outer=T,line=0, cex=compProps$cx)}
    
    
  }
  
  
  if(!is.null(compProps$pdfFile)){dev.off()}
}

#' EICplot
#' 
#' generate one EIC plot for multiple files in one plot window.
#' 
#' @return sends a single EIC plot to the current plotting device
#' 
#' @param EICs item from a list of EICs from Metaboseek:multiEIC
#' @param cx character expansion (font size) factor
#' @param ylim numeric(2) min and max visible rt value (in seconds)
#' @param xlim numeric(2) min and max visible intensity value (in seconds)
#' @param legendtext character() with item for each shown EIC for the plot legend
#' @param colr color range (actual vector of color values)
#' @param heading plot title
#' @param relto normalize intensities to this number
#' @param TIC if TRUE plot TIC
#' @param single TRUE if this is not part of a composite plot
#' @param midline numeric() of y-axis positions where a dotted vertical line should be plotted
#' @param lw line width for plot lines
#' @param yzoom zoom factor into y-axis
#' @param ylabshift shift horizontal position of y axis label 
#' 
#' @export
EICplot <- function(EICs, cx = 1, 
                    ylim = c(0,max(unlist(EICs[[1]][,'tic']))), 
                    xlim = c(min(unlist(EICs[[1]][,'rt'])),
                             max(unlist(EICs[[1]][,'rt'])))/60,
                    legendtext = paste(sub("^([^.]*).*", "\\1",basename(row.names(EICs[[1]])))),
                    colr = topo.colors(nrow(EICs[[1]]), alpha=1),
                    heading = "test",
                    relto = NULL,
                    TIC = F,
                    single = F,
                    midline = 100,
                    lw = 1,
                    yzoom = 1,
                    ylabshift = 0
){
  
  suppressWarnings({
  if(max(ylim)==0 
     || !is.finite(max(ylim))){ylim = c(0,1)}
  })
    
    
  maxint <- format(max(ylim), digits =3, scientific = T)
  
  if(!is.null(relto) && relto != 1 ){
    maxint <- format(relto, digits =3, scientific = T)
  }
  
  if(is.null(relto)){relto <-1}
  
  if(!is.null(yzoom) && yzoom != 1 ){
    ylim[2] <- ylim[2]/yzoom
  }
  
  if(!is.null(relto) && relto != 1 ){ylim <- (ylim/relto)*100}
  
  PlotWindow(cx, 
             ylim, 
             xlim,
             heading,
             single,
             ysci = if(!is.null(relto) && relto != 1){F}else{T},
             liwi = lw,
             ylab = if(!is.null(relto) && relto != 1){"Relative Intensity (%)"}else{"Intensity"},
             ylabshift = ylabshift
  )
  
  if(length(midline)> 0 ){
    for(i in midline){
      abline(v=i/60, lty = 2, lwd = 1)
    }
  }
  
  ##draw the eics
  addLines(EIClist = EICs,
           TIC,
           colr,
           relto = relto,
           liwi = lw
  )    
  #fix axis to not have gaps at edges
  abline(v=min(xlim), h=min(ylim))
  
  par(xpd=NA)
  text(min(xlim), max(ylim)+1.5*strheight("M"),
       labels = maxint, bty="n",
       font = 2, cex=cx*1)
  
  if(!is.null(legendtext)){
    if(is.list(legendtext)){
      legendtext <- legendtext[!duplicated(legendtext),]
    legend("topright",
           # inset=c(-0.08,-0.08),#c(0.025*max(xlim),0.025*max(ylim)),
           legend = legendtext$label, lty=1,lwd=2.5, col=legendtext$color, bty="n",  cex=cx*0.7)
    }else{
      legend("topright",
             # inset=c(-0.08,-0.08),#c(0.025*max(xlim),0.025*max(ylim)),
             legend = legendtext, lty=1,lwd=2.5, col=colr, bty="n",  cex=cx*0.7)
    }
  }
  
}



#' addLines
#'
#' Helper function for EICplot to plot the lines of EICs into a PlottingWindow. 
#' Mass shifts will be handled by plotting different line types
#' 
#' @return plots EIC trace lines into the current plot window
#' 
#' @param EIClist matrix or list of EIC objects (potentially subsetted)
#' @param TIC logical() if TRUE, TIC will be plotted instead of EIC
#' @param colr character() of color values for lines
#' @param relto if not NULL, intensities will be given as relative to this numeric(1)
#' @param liwi line width of plotted lines
#'
addLines <- function(EIClist,
                     TIC = F,
                     colr = topo.colors(1, alpha=1),
                     relto = NULL,
                     liwi = 2
){
  if(TIC){
    reps <- 1
  }else{
    reps <- length(EIClist)
  }
  
  for(n in 1:reps){
    if(TIC){
      int <- EIClist[[n]][,'tic']
    }else{
      int <- EIClist[[n]][,'intensity']
    }
    
    if(!is.null(relto) && relto != 1 ){
      int <- lapply(lapply(int,"/",relto),"*",100)
   # maxint <- format(relto, digits =3, scientific = T)
    }
    
    #convert to minutes
    rts <- lapply(EIClist[[n]][,"rt"],"/",60)
    #  par(xpd=NA)
    # options(scipen=20)
    
    #colr <- topo.colors(2, alpha=1)#rainbow(length(eiccoll[[t]]), s = 1, v = 1, start = 0, end = max(1, length(eiccoll[[t]]) - 1)/length(eiccoll[[t]]), alpha = 0.7)#topo.colors(length(eiccoll[[t]]), alpha=1)
    
    ##draw the eics
    tmp <-mapply(lines, x= rts, y = int, col = as.list(colr), MoreArgs = list(lty = n, lwd = liwi))}
}

#' legendplot
#' 
#' Plot a legend in an otherwise empty plot
#' 
#' @param ... all arguments passed on to \code{\link[graphics]{legend}()}
#' 
#' @return calls a new \code{plot()} with a legend 
#'
legendplot <- function(...){
  
  par(mfrow=c(1,1), 
      mar = c(0.1,0.1,0.1,0.1),
      oma = c(0,0,0,0)
  )
  plot(1, type = "n", axes=FALSE, xlab="", ylab="")
  legend(...)
  
  
}
