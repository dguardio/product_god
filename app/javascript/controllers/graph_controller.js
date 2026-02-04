import { Controller } from "@hotwired/stimulus"
import cytoscape from "cytoscape"

export default class extends Controller {
    static targets = ["container", "info"]

    connect() {
        try {
            this.initCy()
        } catch (e) {
            console.error("Cytoscape init failed:", e)
            this.containerTarget.innerHTML = `<div class="text-red-500 p-4">Graph Error: ${e.message}</div>`
        }

        // If a node is pre-selected or initial load
        // this.loadData() 
    }

    initCy() {
        // Handle potential import discrepancies
        const cyFactory = cytoscape.default || cytoscape; // Lint error risk, but safe logic

        this.cy = cyFactory({
            container: this.containerTarget,
            style: [
                {
                    selector: 'node',
                    style: {
                        'background-color': '#666',
                        'label': 'data(label)',
                        'color': '#fff',
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'font-size': '12px',
                        'width': 60,
                        'height': 60
                    }
                },
                {
                    selector: 'node[type="Person"]',
                    style: { 'background-color': '#3b82f6' } // Blue
                },
                {
                    selector: 'node[type="Company"]',
                    style: { 'background-color': '#ef4444' } // Red
                },
                {
                    selector: 'node[type="Tool"]',
                    style: { 'background-color': '#10b981' } // Green
                },
                {
                    selector: 'edge',
                    style: {
                        'width': 2,
                        'line-color': '#ccc',
                        'target-arrow-color': '#ccc',
                        'target-arrow-shape': 'triangle',
                        'curve-style': 'bezier',
                        'label': 'data(label)',
                        'font-size': '10px',
                        'text-rotation': 'autorotate',
                        'text-background-color': '#fff',
                        'text-background-opacity': 1
                    }
                },
                {
                    selector: ':selected',
                    style: {
                        'border-width': 3,
                        'border-color': '#000'
                    }
                }
            ],
            layout: {
                name: 'grid'
            }
        })

        this.cy.on('tap', 'node', (evt) => {
            this.handleNodeClick(evt.target)
        })
    }

    handleNodeClick(node) {
        const data = node.data()
        this.renderInfo(data)
        this.expandNode(data.id)
    }

    renderInfo(data) {
        if (!this.hasInfoTarget) return

        this.infoTarget.innerHTML = `
      <div class="p-4 bg-white shadow rounded-lg border border-gray-200">
        <h3 class="font-bold text-lg text-gray-900">${data.label}</h3>
        <span class="inline-block px-2 py-1 text-xs font-semibold text-white bg-gray-500 rounded mb-2">${data.type}</span>
        <p class="text-sm text-gray-600">${data.description || "No description available."}</p>
      </div>
    `
    }

    expandNode(nodeId) {
        fetch(`/knowledge_graph/visualize?node_id=${nodeId}`)
            .then(r => {
                if (!r.ok) throw new Error("Network response was not ok");
                return r.json();
            })
            .then(elements => {
                this.cy.add(elements)
                const layout = this.cy.layout({
                    name: 'cose',
                    animate: true
                })
                layout.run()
            })
            .catch(error => {
                console.error("Error expanding node:", error)
                alert("Failed to load node data.")
            })
    }

    // Called by clicking a search result
    loadNode(event) {
        let nodeId;

        // Check if it's a click event from a DOM element
        if (event.currentTarget && event.currentTarget.dataset.id) {
            nodeId = event.currentTarget.dataset.id;
        }
        // Check if it's a custom event (e.g. dispatched)
        else if (event.detail && event.detail.id) {
            nodeId = event.detail.id;
        }

        if (!nodeId) return;

        this.cy.elements().remove()
        this.expandNode(nodeId)

        // Also show details for this node immediately if possible
        // We can fetch details or use dataset
        if (event.currentTarget && event.currentTarget.dataset.description) {
            this.renderInfo({
                label: event.currentTarget.dataset.label,
                type: event.currentTarget.dataset.type,
                description: event.currentTarget.dataset.description
            })
        }
    }
}
