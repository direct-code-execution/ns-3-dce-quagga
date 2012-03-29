/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */

#include "ns3/network-module.h"
#include "ns3/core-module.h"
#include "ns3/internet-module.h"
#include "ns3/dce-module.h"
#include "ns3/quagga-helper.h"
#include "ns3/point-to-point-helper.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("DceQuaggaOspfd");

static void RunIp (Ptr<Node> node, Time at, std::string str)
{
  DceApplicationHelper process;
  ApplicationContainer apps;
  process.SetBinary ("ip");
  process.SetStackSize (1<<16);
  process.ResetArguments();
  process.ParseArguments(str.c_str ());
  apps = process.Install (node);
  apps.Start (at);
}

static void AddAddress (Ptr<Node> node, Time at, const char *name, const char *address)
{
  std::ostringstream oss;
  oss << "-f inet addr add " << address << " dev " << name;
  RunIp (node, at, oss.str ());
}

// Parameters
uint32_t nNodes = 2;
uint32_t stopTime = 600;
std::string netStack = "ns3";


int main (int argc, char *argv[])
{
  CommandLine cmd;
  cmd.AddValue ("nNodes", "Number of Router nodes", nNodes);
  cmd.AddValue ("stopTime", "Time to stop(seconds)", stopTime);
  cmd.AddValue ("netStack", "What network stack", netStack);
  cmd.Parse (argc,argv);

  // 
  //  Step 1
  //  Node Basic Configuration
  // 
  NodeContainer nodes;
  nodes.Create (nNodes);

  PointToPointHelper pointToPoint;
  pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
  pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));

  NetDeviceContainer devices;
  devices = pointToPoint.Install (nodes);
  DceManagerHelper processManager;

  // 
  // 
  // Address Configuration
  // 
  // 
  if (netStack == "ns3")
    {
      Ipv4AddressHelper ipv4AddrHelper;
      Ipv6AddressHelper ipv6AddrHelper;
      // Internet stack install
      InternetStackHelper stack;    // IPv4 is required for GlobalRouteMan
      Ipv4DceRoutingHelper ipv4RoutingHelper;
      stack.SetRoutingHelper (ipv4RoutingHelper);
      stack.Install (nodes);

      ipv4AddrHelper.SetBase ("10.0.0.0", "255.255.255.0");
      Ipv4InterfaceContainer interfaces = ipv4AddrHelper.Assign (devices);
      Ipv4GlobalRoutingHelper::PopulateRoutingTables ();

      processManager.SetNetworkStack("ns3::Ns3SocketFdFactory");
      processManager.Install (nodes);

      QuaggaHelper quagga;
      quagga.EnableOspf (nodes);
      quagga.EnableOspfDebug (nodes);
      quagga.EnableZebraDebug (nodes);
      quagga.Install (nodes);  
    }
  else if (netStack == "linux")
    {
      //      processManager.SetLoader ("ns3::DlmLoaderFactory");
      processManager.SetTaskManagerAttribute ("FiberManagerType", 
                                              EnumValue (0));
      processManager.SetNetworkStack("ns3::LinuxSocketFdFactory",
                                     "Library", StringValue ("libnet-next-2.6.so"));
      processManager.Install (nodes);

      // IP address configuration
      AddAddress (nodes.Get (0), Seconds (0.1), "sim0", "10.0.0.1/24");
      RunIp (nodes.Get (0), Seconds (0.11), "link set lo up");
      RunIp (nodes.Get (0), Seconds (0.11), "link set sim0 up");

      AddAddress (nodes.Get (1), Seconds (0.1), "sim0", "10.0.0.2/24");
      RunIp (nodes.Get (1), Seconds (0.11), "link set lo up");
      RunIp (nodes.Get (1), Seconds (0.11), "link set sim0 up");
      RunIp (nodes.Get (0), Seconds (0.2), "link show");
      RunIp (nodes.Get (0), Seconds (0.3), "route show table all");
      RunIp (nodes.Get (0), Seconds (0.4), "addr list");

      QuaggaHelper quagga;
      quagga.UseManualConfig (nodes);
      quagga.Install (nodes);  

      DceApplicationHelper process;
      ApplicationContainer apps;

      //      GenerateConfigOspf (node);
      process.ResetArguments ();
      process.SetStackSize (1<<16);
      process.SetBinary ("ospfd");
      process.ParseArguments("-f /usr/local/etc/ospfd.conf");
      apps = process.Install (nodes);
      for (uint32_t i = 0; i < nodes.GetN (); i++)
        {
          apps.Get(i)->SetStartTime (Seconds (2.0 + 1 * i));
        }
    }

  pointToPoint.EnablePcapAll ("dce-quagga-ospfd");

  // 
  // Step 9
  // Now It's ready to GO!
  // 
  if (stopTime != 0)
    {
      Simulator::Stop (Seconds (stopTime));
    }
  Simulator::Run ();
  Simulator::Destroy ();

  return 0;
}
