import UIKit
import GoogleMaps

/// Subclass of GMSMapView to suit Pace's use case.
class MapView: GMSMapView {
    // private var gridMapManager = Constants.defaultGridManager
    private var path = GMSMutablePath()
    private var currentMapPath: GMSPolyline?
    private let gridMapManager = GridMapManager.default
    private var followingRoute: GMSPolyline?

    /// Setup the view
    ///
    /// - Parameter delegate: delegate of this view
    func setup(_ delegate: GMSMapViewDelegate) {
        animate(toZoom: Constants.initialZoom)
        isMyLocationEnabled = true
        settings.myLocationButton = true

        // Required to activate gestures in googleMapView
        settings.consumesGesturesInView = false
        self.delegate = delegate
        setMinZoom(Float(Constants.minZoom), maxZoom: Float(Constants.maxZoom))
    }

    /// Add an image to the map. Required to plot start and end flag.
    ///
    /// - Parameters:
    ///   - image: Image of marker.
    ///   - position: position to plot the image.
    func addMarker(_ image: String, position: CLLocationCoordinate2D) {
        let marker = GMSMarker(position: position)
        marker.map = self
        marker.icon = UIImage(named: image)
    }

    /// Add a position to the route and render it
    ///
    /// - Parameter position: the position to add to the route.
    func addPositionToRoute(_ position: CLLocationCoordinate2D) {
        path.add(position)
        currentMapPath?.map = nil
        currentMapPath = drawPath(path: path)
    }

    /// Function to prepare view to start the run.
    ///
    /// - Parameter position: the starting position of the run.
    func startRun(at position: CLLocationCoordinate2D, followingRun: Run? = nil) {
        clearRoutes()
        clear()
        path.add(position)
        addMarker(Constants.startFlag, position: position)
        guard let followingRun = followingRun else {
            return
        }
        renderFollowingRun(followingRun)
    }

    /// Function to prepare view to resume the run
    ///
    /// - Parameter run: the existing run
    func startRun(with run: OngoingRun) {
        clearRoutes()
        clear()
        if let firstPos = run.checkpoints.first?.location?.coordinate {
            addMarker(Constants.startFlag, position: firstPos)
        }
        for checkpoint in run.checkpoints {
            guard let coordinate = checkpoint.location?.coordinate else {
                continue
            }
            path.add(coordinate)
        }
        guard let followingRun = run.paceRun else {
            return
        }
        renderFollowingRun(followingRun)
    }

    private func renderFollowingRun(_ run: Run) {
        let checkpoints = run.checkpoints
        let followPath = GMSMutablePath()
        for checkpoint in checkpoints {
            guard let position = checkpoint.location?.coordinate else {
                continue
            }
            followPath.add(position)
        }
        followingRoute = drawPath(path: followPath, .red)
    }

    /// Function to prepare view to end the run.
    func completeRun() {
        clearRoutes()
        clear() // Required for clearing flags
    }

    /// Render the given route onto map view
    ///
    /// - Parameter route: the route that will be rendered.
    func renderRoute(_ route: Route) {
        clearRoutes()
        guard
            let locations = route.creatorRun?.locations,
            let startingLocation = route.startingLocation else {
            return
        }
        locations.forEach { path.add($0.coordinate) }
        currentMapPath = drawPath(path: path)
        setCameraPosition(startingLocation.coordinate)
    }

    /// Clear the route's drawing from the map view.
    func clearRoutes() {
        path.removeAllCoordinates()
        currentMapPath?.map = nil
        currentMapPath = nil

        followingRoute?.map = nil
        followingRoute = nil
    }

    func drawPath(path: GMSPath, _ color: UIColor = .blue) -> GMSPolyline? {
        let mapPaths = GMSPolyline(path: path)
        mapPaths.strokeColor = color
        mapPaths.strokeWidth = 5
        mapPaths.map = self
        return mapPaths
    }

    func drawRun(_ run: Run?, _ color: UIColor = .blue) -> GMSPolyline? {
        guard let run = run else {
            return nil
        }
        let path = GMSMutablePath()
        for checkpoint in run.checkpoints {
            guard let coordinate = checkpoint.location?.coordinate else {
                continue
            }
            path.add(coordinate)
        }
        return drawPath(path: path, color)
    }

    var projectedMapBound: GridBound {
        let topLeft = projection.visibleRegion().farLeft
        let topRight = projection.visibleRegion().farRight
        let bottomLeft = projection.visibleRegion().nearLeft
        let bottomRight = projection.visibleRegion().nearRight
        return GridBound(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
    }

    var diameter: CLLocationDistance {
        return projectedMapBound.diameter
    }

    var viewingGrids: [GridNumber] {
        let manager = gridMapManager.getGridManager(zoom)
        return manager.getBoundedGrid(projectedMapBound)
    }

    var nearestZoom: Int {
        return gridMapManager.getNearestZoom(zoom)
    }

    var isMapLock = false {
        willSet {
            if newValue {
                settings.setAllGesturesEnabled(false)
                settings.zoomGestures = true
            } else {
                settings.setAllGesturesEnabled(true)
            }
        }
    }
}
