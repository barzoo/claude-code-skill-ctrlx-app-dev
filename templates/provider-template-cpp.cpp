/**
 * ctrlX Data Layer Provider Template (C++)
 * SDK: comm.datalayer >= 2.4
 * Build: see CMakeLists.txt
 */
#include <csignal>
#include <iostream>
#include <memory>
#include <thread>
#include <chrono>

#include "comm/datalayer/datalayer.h"
#include "comm/datalayer/datalayer_system.h"
#include "comm/datalayer/metadata_generated.h"

using namespace comm::datalayer;

static volatile bool g_running = true;

void signal_handler(int sig) {
    g_running = false;
}

// ── Node implementation ──────────────────────────────────────────────────────

class SensorNode : public IProviderNode {
public:
    explicit SensorNode(const std::string& path) : m_path(path), m_value(0.0) {}

    void onRead(const std::string& address, IProviderNodeResult* result) override {
        Variant v;
        v.setValue(m_value);
        result->setItem(v);
        result->finish(DlResult::DL_OK);
    }

    void onWrite(const std::string& address, const Variant& data,
                 IProviderNodeResult* result) override {
        if (data.getType() == VariantType::FLOAT64) {
            m_value = data.getValue<double>();
            std::cout << "[provider] Written: " << m_value << "\n";
            result->finish(DlResult::DL_OK);
        } else {
            result->finish(DlResult::DL_TYPE_MISMATCH);
        }
    }

    void onMetadata(const std::string& address,
                    IProviderNodeResult* result) override {
        // Build metadata flatbuffer
        flatbuffers::FlatBufferBuilder builder;
        auto unit = builder.CreateString("°C");
        auto desc = builder.CreateString("Sensor temperature value");
        MetadataBuilder mb(builder);
        mb.add_unit(unit);
        mb.add_description(desc);
        builder.Finish(mb.Finish());
        Variant v;
        v.setFlatbuffers(builder.GetBufferPointer(), builder.GetSize());
        result->setItem(v);
        result->finish(DlResult::DL_OK);
    }

private:
    std::string m_path;
    double m_value;
};

// ── Main ─────────────────────────────────────────────────────────────────────

int main() {
    signal(SIGTERM, signal_handler);
    signal(SIGINT, signal_handler);

    // Initialize system (empty string = use env/default)
    DatalayerSystem system("");
    system.start(false);

    // Use IPC socket inside snap
    const std::string url = "ipc://";
    auto provider = system.factory()->createProvider(url);
    if (!provider) {
        std::cerr << "[provider] Failed to create provider\n";
        return 1;
    }

    auto result = provider->start();
    if (result != DlResult::DL_OK) {
        std::cerr << "[provider] Start failed: " << toString(result) << "\n";
        return 1;
    }

    // Register nodes
    const std::vector<std::string> paths = {
        "{company}/{app}/sensor/value",
        "{company}/{app}/sensor/status",
    };

    std::vector<std::shared_ptr<SensorNode>> nodes;
    for (const auto& path : paths) {
        auto node = std::make_shared<SensorNode>(path);
        auto r = provider->registerNode(path, node.get());
        if (r != DlResult::DL_OK) {
            std::cerr << "[provider] Failed to register " << path << ": "
                      << toString(r) << "\n";
        } else {
            std::cout << "[provider] Registered: " << path << "\n";
        }
        nodes.push_back(node);
    }

    std::cout << "[provider] Running. Send SIGTERM to stop.\n";

    while (g_running) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    // Graceful shutdown
    for (const auto& path : paths) {
        provider->unregisterNode(path);
    }
    provider->stop();
    system.stop();
    std::cout << "[provider] Stopped.\n";
    return 0;
}
