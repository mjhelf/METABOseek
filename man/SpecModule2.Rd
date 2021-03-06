% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Module_SpecModule2.R
\name{SpecModule2}
\alias{SpecModule2}
\alias{SpecModule2UI}
\title{SpecModule2}
\usage{
SpecModule2(
  input,
  output,
  session,
  values,
  reactives = reactive({     list(scantable = NULL, type = "ms2", spectrum = NULL,
    specinfo = NULL, xrange = NULL, markermz = NULL) })
)

SpecModule2UI(id)
}
\arguments{
\item{input}{arguments necessary for use with 
\code{\link[shiny]{callModule}()}}

\item{output}{arguments necessary for use with 
\code{\link[shiny]{callModule}()}}

\item{session}{arguments necessary for use with 
\code{\link[shiny]{callModule}()}}

\item{values}{a \code{\link[shiny]{reactiveValues}} object that in effect 
gives read and write access to external objects}

\item{reactives}{a list, wrapped in a \code{\link[shiny]{reactive}()} 
expression with settings for this module. See \code{details}.}

\item{id}{id to be used to define a namespace via  \code{\link[shiny]{NS}()} 
(must match \code{id} in \code{\link[shiny]{callModule}} 
for the server Module)}
}
\value{
If the server module for this Module returns something,
 it is described in \code{Details}.
}
\description{
Module for interactive mass spectrum view
}
\details{
\subsection{reactives}{
Can either be a list with entries \code{scanTable} and \code{type}, 
specifying inputs for the \link[Metaboseek]{getScanInfo}, OR
a list with entries \code{spectrum} and \code{specinfo}. 

\describe{
\item{scanTable}{}
\item{type}{}
\item{spectrum}{}
\item{specinfo}{}
}
}
}
\section{Functions}{
\itemize{
\item \code{SpecModule2}: Server module, to be called with \link[shiny]{callModule}()

\item \code{SpecModule2UI}: UI function for SpecModule2
}}

\examples{
\dontrun{
library(shiny)

ui <- SpecModule2UI("examplemodule")

server <- function(input, output) {
    MseekMinimalServer(diagnostics = F, data = F, tables = F)
    
    ExampleModule <- callModule(SpecModule2, "examplemodule", values,
                                reactives = reactive({
                                    list(spectrum = data.frame(mz = c(100,200,250,300,400),
                                                               intensity = c(1000,2000,3000,1000,3000)))
                                    
                                }))
}

# Create Shiny app ----
shinyApp(ui, server)
}

}
\seealso{
\code{\link{values}} for a description of the \code{values} object
}
