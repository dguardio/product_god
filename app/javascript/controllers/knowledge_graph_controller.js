import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"

// Helper for colors based on node type
const NODE_COLORS = {
    person: '#3B82F6', // Blue
    company: '#EF4444', // Red
    tool: '#10B981', // Green
    framework: '#8B5CF6', // Purple
    book: '#F59E0B', // Amber
    concept: '#6B7280', // Gray
    default: '#9CA3AF'
}

export default class extends Controller {
    static targets = ["loader", "infoPanel", "nodeTitle", "nodeType", "nodeDesc"]

    connect() {
        console.log("KnowledgeGraph Controller Connected")
        this.initCytoscape()
        this.fetchData()
    }

    initCytoscape() {
        this.cy = cytoscape({
            container: document.getElementById('cy'), // container to render in

            // Initial style
            style: [
                {
                    selector: 'node',
                    style: {
                        'background-color': (ele) => {
                            const type = (ele.data('type') || 'default').toLowerCase()
                            return NODE_COLORS[type] || NODE_COLORS.default
                        },
                        'label': 'data(label)',
                        'color': '#1f2937',
                        'font-size': '12px',
                        'font-weight': 'bold',
                        'text-valign': 'bottom',
                        'text-margin-y': 5,
                        'width': (ele) => Math.min(60, 20 + (ele.data('weight') * 2)), // Size by weight
                        'height': (ele) => Math.min(60, 20 + (ele.data('weight') * 2)),
                        'text-background-opacity': 0.7,
                        'text-background-color': '#ffffff',
                        'text-background-padding': '2px',
                        'text-background-shape': 'roundrectangle'
                    }
                },
                {
                    selector: 'edge',
                    style: {
                        'width': 1.5,
                        'line-color': '#E5E7EB', // Gray-200
                        'target-arrow-color': '#E5E7EB',
                        'target-arrow-shape': 'triangle',
                        'curve-style': 'bezier',
                        'opacity': 0.8
                    }
                },
                {
                    selector: 'node:selected',
                    style: {
                        'border-width': 4,
                        'border-color': '#FCD34D', // Yellow-300 ring
                        'background-color': '#111827' // Darker
                    }
                }
            ],

            // Interaction options
            minZoom: 0.1,
            maxZoom: 3,
            wheelSensitivity: 0.2
        })

        // Event Listeners
        this.cy.on('tap', 'node', (evt) => this.showNodeInfo(evt.target))
        this.cy.on('tap', (evt) => {
            if (evt.target === this.cy) {
                this.closePanel()
            }
        })
    }

    changeScope(event) {
        this.currentScope = event.target.value
        this.fetchData()
    }

    async fetchData(nodeId = null) {
        this.loaderTarget.classList.remove('hidden')

        try {
            let url = `/knowledge_graph/visualize`
            const params = new URLSearchParams()

            if (nodeId) params.append('node_id', nodeId)
            if (this.currentScope) params.append('scope', this.currentScope)

            if (params.toString()) {
                url += `?${params.toString()}`
            }

            const response = await fetch(url)
            const data = await response.json()

            if (data.length === 0 && !nodeId) {
                // Empty graph
                console.warn("No data found for graph")
                // Clear graph if filtering returned empty
                this.cy.elements().remove()
                this.loaderTarget.classList.add('hidden')
                return
            }

            // If global load (no nodeId), replace elements. 
            // If incremental (nodeId), add them.
            if (!nodeId) {
                this.cy.elements().remove()
            }

            this.cy.add(data)

            // Run Layout
            const layout = this.cy.layout({
                name: 'cose',
                animate: true,
                randomize: !nodeId, // Randomize only on first load
                padding: 50,
                nodeRepulsion: 8000,
                idealEdgeLength: 100,
                edgeElasticity: 100
            })

            layout.run()

        } catch (error) {
            console.error("Failed to fetch graph data:", error)
        } finally {
            this.loaderTarget.classList.add('hidden')
        }
    }

    showNodeInfo(node) {
        const data = node.data()
        this.selectedNodeId = data.id

        // Populate Side Panel
        this.nodeTitleTarget.textContent = data.label
        this.nodeTypeTarget.textContent = data.type || 'Unknown'

        // Set badge color dynamically
        const type = (data.type || 'default').toLowerCase()
        const color = NODE_COLORS[type] || NODE_COLORS.default
        this.nodeTypeTarget.style.backgroundColor = color + '20' // 20 = low opacity hex
        this.nodeTypeTarget.style.color = color

        this.nodeDescTarget.textContent = data.description || "No description available."

        // Show Panel
        this.infoPanelTarget.classList.remove('hidden')
    }

    closePanel() {
        this.infoPanelTarget.classList.add('hidden')
        this.selectedNodeId = null
    }

    expandNode() {
        if (this.selectedNodeId) {
            this.fetchData(this.selectedNodeId)
        }
    }

    resetZoom() {
        this.cy.fit()
    }
}
