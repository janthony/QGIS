typedef QMap<QString, QString> QgsStringMap;

typedef QList<QgsSymbol*> QgsSymbolList;
typedef QMap<QString, QgsSymbol* > QgsSymbolMap;

typedef QList< QPair<QString, QPixmap> > QgsLegendSymbologyList;
typedef QList< QPair<QString, QgsSymbol*> > QgsLegendSymbolList;

class QgsSymbolLevelItem
{
%TypeHeaderCode
#include <qgsrenderer.h>
%End
  public:
    QgsSymbolLevelItem( QgsSymbol* symbol, int layer );
    QgsSymbol* symbol();
    int layer();
};

// every level has list of items: symbol + symbol layer num
// typedef QList< QgsSymbolLevelItem > QgsSymbolLevel;

// this is a list of levels
// typedef QList< QgsSymbolLevel > QgsSymbolLevelOrder;


//////////////
// renderers

class QgsFeatureRenderer
{
%TypeHeaderCode
#include <qgsrenderer.h>
%End

%ConvertToSubClassCode
  if (sipCpp->type() == "singleSymbol")
    sipType = sipType_QgsSingleSymbolRenderer;
  else if (sipCpp->type() == "categorizedSymbol")
    sipType = sipType_QgsCategorizedSymbolRenderer;
  else if (sipCpp->type() == "graduatedSymbol")
    sipType = sipType_QgsGraduatedSymbolRenderer;
  else if (sipCpp->type() == "RuleRenderer")
    sipType = sipType_QgsRuleBasedRenderer;
  else if (sipCpp->type() == "heatmapRenderer")
    sipType = sipType_QgsHeatmapRenderer;
  else if (sipCpp->type() == "invertedPolygonRenderer")
    sipType = sipType_QgsInvertedPolygonRenderer;
  else if (sipCpp->type() == "pointCluster")
    sipType = sipType_QgsPointClusterRenderer;
  else if (sipCpp->type() == "pointDisplacement")
    sipType = sipType_QgsPointDisplacementRenderer;
  else if (sipCpp->type() == "25dRenderer")
    sipType = sipType_Qgs25DRenderer;
  else if (sipCpp->type() == "nullSymbol")
    sipType = sipType_QgsNullSymbolRenderer;
  else
    sipType = 0;
%End

  public:
    // renderer takes ownership of its symbols!

    //! return a new renderer - used by default in vector layers
    static QgsFeatureRenderer* defaultRenderer( QgsWkbTypes::GeometryType geomType ) /Factory/;

    QString type() const;

    /** To be overridden
     *
     * Must be called between startRender() and stopRender() calls.
     * @param feature feature
     * @param context render context
     * @return returns pointer to symbol or 0 if symbol was not found
     * @note added in QGIS 2.12
     */
    virtual QgsSymbol* symbolForFeature( QgsFeature& feature, QgsRenderContext& context ) = 0;

    /**
     * Return symbol for feature. The difference compared to symbolForFeature() is that it returns original
     * symbol which can be used as an identifier for renderer's rule - the former may return a temporary replacement
     * of a symbol for use in rendering.
     * @note added in 2.12
     */
    virtual QgsSymbol* originalSymbolForFeature( QgsFeature& feature, QgsRenderContext& context );

    /**
     * Return legend keys matching a specified feature.
     * @note added in 2.14
     */
    virtual QSet< QString > legendKeysForFeature( QgsFeature& feature, QgsRenderContext& context );

    /**
     * Needs to be called when a new render cycle is started
     *
     * @param context  Additional information passed to the renderer about the job which will be rendered
     * @param fields   The fields available for rendering
     * @return         Information passed back from the renderer that can e.g. be used to reduce the amount of requested features
     */
    virtual void startRender( QgsRenderContext& context, const QgsFields& fields ) = 0;

    /**
     * Needs to be called when a render cycle has finished to clean up.
     */
    virtual void stopRender( QgsRenderContext& context ) = 0;

    /**
     * If a renderer does not require all the features this method may be overridden
     * and return an expression used as where clause.
     * This will be called once after {@link startRender()} and before the first call
     * to {@link renderFeature()}.
     * By default this returns a null string and all features will be requested.
     * You do not need to specify the extent in here, this is taken care of separately and
     * will be combined with a filter returned from this method.
     *
     * @return An expression used as where clause
     */
    virtual QString filter( const QgsFields& fields = QgsFields() );

    /**
     * Returns a set of attributes required for this renderer.
     *
     * TODO QGIS3: Change QList to QSet
     */
    virtual QList<QString> usedAttributes() = 0;

    /**
     * Returns true if this renderer requires the geometry to apply the filter.
     */
    virtual bool filterNeedsGeometry() const;

    virtual ~QgsFeatureRenderer();

    virtual QgsFeatureRenderer* clone() const = 0 /Factory/;

    /**
     * Render a feature using this renderer in the given context.
     * Must be called between startRender() and stopRender() calls.
     * Default implementation renders a symbol as determined by symbolForFeature() call.
     * Returns true if the feature has been returned (this is used for example
     * to determine whether the feature may be labelled).
     *
     * If layer is not -1, the renderer should draw only a particula layer from symbols
     * (in order to support symbol level rendering).
     */
    virtual bool renderFeature( QgsFeature& feature, QgsRenderContext& context, int layer = -1, bool selected = false, bool drawVertexMarker = false );

    //! for debugging
    virtual QString dump() const;

    enum Capability
    {
      SymbolLevels,           // rendering with symbol levels (i.e. implements symbols(), symbolForFeature())
      MoreSymbolsPerFeature,  // may use more than one symbol to render a feature: symbolsForFeature() will return them
      Filter,                 // features may be filtered, i.e. some features may not be rendered (categorized, rule based ...)
      ScaleDependent          // depends on scale if feature will be rendered (rule based )
    };

    typedef QFlags<QgsFeatureRenderer::Capability> Capabilities;

    //! returns bitwise OR-ed capabilities of the renderer
    virtual QgsFeatureRenderer::Capabilities capabilities();


    /** Returns list of symbols used by the renderer.
     * @param context render context
     * @note added in QGIS 2.12
     */
    virtual QgsSymbolList symbols( QgsRenderContext& context );

    bool usingSymbolLevels() const;
    void setUsingSymbolLevels( bool usingSymbolLevels );

    //! create a renderer from XML element
    static QgsFeatureRenderer* load( QDomElement& symbologyElem ) /Factory/;

    //! store renderer info to XML element
    virtual QDomElement save( QDomDocument& doc );

    //! create the SLD UserStyle element following the SLD v1.1 specs with the given name
    //! @note added in 2.8
    virtual QDomElement writeSld( QDomDocument& doc, const QString& styleName ) const;

    /** Create a new renderer according to the information contained in
     * the UserStyle element of a SLD style document
     * @param node the node in the SLD document whose the UserStyle element
     * is a child
     * @param geomType the geometry type of the features, used to convert
     * Symbolizer elements
     * @param errorMessage it will contain the error message if something
     * went wrong
     * @return the renderer
     */
    static QgsFeatureRenderer* loadSld( const QDomNode &node, QgsWkbTypes::GeometryType geomType, QString &errorMessage ) /Factory/;

    //! used from subclasses to create SLD Rule elements following SLD v1.1 specs
    virtual void toSld( QDomDocument& doc, QDomElement &element ) const;

    //! return a list of symbology items for the legend
    virtual QgsLegendSymbologyList legendSymbologyItems( QSize iconSize );

    //! items of symbology items in legend should be checkable
    //! @note added in 2.5
    virtual bool legendSymbolItemsCheckable() const;

    //! items of symbology items in legend is checked
    //! @note added in 2.5
    virtual bool legendSymbolItemChecked( const QString& key );

    //! item in symbology was checked
    //! @note added in 2.5
    virtual void checkLegendSymbolItem( const QString& key, bool state = true );

    /** Sets the symbol to be used for a legend symbol item.
     * @param key rule key for legend symbol
     * @param symbol new symbol for legend item. Ownership is transferred to renderer.
     * @note added in QGIS 2.14
     */
    virtual void setLegendSymbolItem( const QString& key, QgsSymbol* symbol /Transfer/ );

    //! return a list of item text / symbol
    //! @note not available in python bindings
    // virtual QgsLegendSymbolList legendSymbolItems( double scaleDenominator = -1, const QString& rule = "" );

    //! Return a list of symbology items for the legend. Better choice than legendSymbolItems().
    //! Default fallback implementation just uses legendSymbolItems() implementation
    //! @note added in 2.6
    virtual QgsLegendSymbolListV2 legendSymbolItemsV2() const;

    //! If supported by the renderer, return classification attribute for the use in legend
    //! @note added in 2.6
    virtual QString legendClassificationAttribute() const;

    //! set type and size of editing vertex markers for subsequent rendering
    void setVertexMarkerAppearance( int type, int size );

    /** Returns whether the renderer will render a feature or not.
     * Must be called between startRender() and stopRender() calls.
     * Default implementation uses symbolForFeature().
     * @note added in QGIS 2.12
     */
    virtual bool willRenderFeature( QgsFeature& feat, QgsRenderContext& context );

    /** Returns list of symbols used for rendering the feature.
     * For renderers that do not support MoreSymbolsPerFeature it is more efficient
     * to use symbolForFeature()
     * @note added in QGIS 2.12
     */
    virtual QgsSymbolList symbolsForFeature( QgsFeature& feat, QgsRenderContext& context );

    /** Equivalent of originalSymbolsForFeature() call
     * extended to support renderers that may use more symbols per feature - similar to symbolsForFeature()
     * @note added in 2.12     */
    virtual QgsSymbolList originalSymbolsForFeature( QgsFeature& feat, QgsRenderContext& context );

    /** Allows for a renderer to modify the extent of a feature request prior to rendering
     * @param extent reference to request's filter extent. Modify extent to change the
     * extent of feature request
     * @param context render context
     * @note added in QGIS 2.7
     */
    virtual void modifyRequestExtent( QgsRectangle& extent, QgsRenderContext& context );

    /** Returns the current paint effect for the renderer.
     * @returns paint effect
     * @note added in QGIS 2.9
     * @see setPaintEffect
     */
    QgsPaintEffect* paintEffect() const;

    /** Sets the current paint effect for the renderer.
     * @param effect paint effect. Ownership is transferred to the renderer.
     * @note added in QGIS 2.9
     * @see paintEffect
     */
    void setPaintEffect( QgsPaintEffect* effect /Transfer/);

    /** Returns whether the renderer must render as a raster.
     * @note added in QGIS 2.12
     * @see setForceRasterRender
     */
    bool forceRasterRender() const;

    /** Sets whether the renderer should be rendered to a raster destination.
     * @param forceRaster set to true if renderer must be drawn on a raster surface.
     * This may be desirable for highly detailed layers where rendering as a vector
     * would result in a large, complex vector output.
     * @see forceRasterRender
     * @note added in QGIS 2.12
     */
    void setForceRasterRender( bool forceRaster );

    /**
     * Get the order in which features shall be processed by this renderer.
     * @note added in QGIS 2.14
     * @note this property has no effect if orderByEnabled() is false
     * @see orderByEnabled()
     */
    QgsFeatureRequest::OrderBy orderBy() const;

    /**
     * Define the order in which features shall be processed by this renderer.
     * @note this property has no effect if orderByEnabled() is false
     * @note added in QGIS 2.14
     * @see setOrderByEnabled()
     */
    void setOrderBy( const QgsFeatureRequest::OrderBy& orderBy );

    /**
     * Returns whether custom ordering will be applied before features are processed by this renderer.
     * @note added in QGIS 2.14
     * @see orderBy()
     * @see setOrderByEnabled()
     */
    bool orderByEnabled() const;

    /**
     * Sets whether custom ordering should be applied before features are processed by this renderer.
     * @param enabled set to true to enable custom feature ordering
     * @note added in QGIS 2.14
     * @see setOrderBy()
     * @see orderByEnabled()
     */
    void setOrderByEnabled( bool enabled );

    /** Sets an embedded renderer (subrenderer) for this feature renderer. The base class implementation
     * does nothing with subrenderers, but individual derived classes can use these to modify their behaviour.
     * @param subRenderer the embedded renderer. Ownership will be transferred.
     * @see embeddedRenderer()
     * @note added in QGIS 2.16
     */
    virtual void setEmbeddedRenderer( QgsFeatureRenderer* subRenderer /Transfer/ );

    /** Returns the current embedded renderer (subrenderer) for this feature renderer. The base class
     * implementation does not use subrenderers and will always return null.
     * @see setEmbeddedRenderer()
     * @note added in QGIS 2.16
     */
    virtual const QgsFeatureRenderer* embeddedRenderer() const;

  protected:
    QgsFeatureRenderer( const QString& type );

    void renderFeatureWithSymbol( QgsFeature& feature,
                                  QgsSymbol* symbol,
                                  QgsRenderContext& context,
                                  int layer,
                                  bool selected,
                                  bool drawVertexMarker );

    //! render editing vertex marker at specified point
    void renderVertexMarker( QPointF pt, QgsRenderContext& context );
    //! render editing vertex marker for a polyline
    void renderVertexMarkerPolyline( QPolygonF& pts, QgsRenderContext& context );
    //! render editing vertex marker for a polygon
    void renderVertexMarkerPolygon( QPolygonF& pts, QList<QPolygonF>* rings, QgsRenderContext& context );

    /**
     * Creates a point in screen coordinates from a wkb string in map
     * coordinates
     */
    static QPointF _getPoint( QgsRenderContext& context, const QgsPointV2& point );

    /**
     * Clones generic renderer data to another renderer.
     * Currently clones
     *  * Order By
     *  * Paint Effect
     *
     * @param destRenderer destination renderer for copied effect
     */
    void copyRendererData( QgsFeatureRenderer *destRenderer ) const;

    /** @note this function is used to convert old sizeScale expresssions to symbol
     * level DataDefined size
     */
    static void convertSymbolSizeScale( QgsSymbol * symbol, QgsSymbol::ScaleMethod method, const QString & field );
    /** @note this function is used to convert old rotations expresssions to symbol
     * level DataDefined angle
     */
    static void convertSymbolRotation( QgsSymbol * symbol, const QString & field );

  private:
    QgsFeatureRenderer( const QgsFeatureRenderer & );
    QgsFeatureRenderer & operator=( const QgsFeatureRenderer & );

};
